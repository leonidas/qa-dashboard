{-# LANGUAGE OverloadedStrings, DeriveDataTypeable #-}

import Control.Applicative
import Control.Arrow
import Control.Exception
import Control.Monad
import Data.Maybe
import Data.List
import Data.Typeable
import Network.Browser
import Network.HTTP
import Network.HTTP.Auth
import Network.HTTP.Proxy
import Network.URI
import Network.Stream
import System.IO
import System.Directory
import Text.JSON
import Text.JSON.Pretty

import qualified Data.ByteString.UTF8 as UTF8
import qualified Data.String as S

sinceFilePath = "last-report.txt"

type URL = String

data Config          = Config ReportsConfig DashboardConfig
data ServiceConfig   = ServiceConfig URL (Maybe AuthConfig) (Maybe ProxyConfig)
data ReportsConfig   = ReportsConfig ServiceConfig FetchCount
data DashboardConfig = DashboardConfig ServiceConfig Token
data AuthConfig      = BasicAuth Username Password
data ProxyConfig     = ProxyConfig URL (Maybe AuthConfig)

type FetchCount = Int
type Username   = String
type Password   = String
type Token      = String

type DateString = String

data ReportError = ReportError deriving (Show, Typeable)
instance Exception ReportError

newtype ReportExport a = ReportExport
    { runRE :: Config -> IO a }

instance Functor ReportExport where
    fmap f a = ReportExport $ fmap f . runRE a

instance Monad ReportExport where
    return  = ReportExport . const . return
    a >>= f = ReportExport $ \cfg -> do
        a' <- runRE a cfg
        runRE (f a') cfg

data Report = Report
    { reportSrc  :: JSValue
    , reportDate :: DateString
    }

instance S.IsString JSString where
    fromString = toJSString

instance JSON Config where
    showJSON = undefined
    readJSON (JSObject o) = Config <$>
        (valFromObj "reports" o) <*>
        (valFromObj "dashboard" o)

instance JSON ReportsConfig where
    showJSON = undefined
    readJSON js@(JSObject o) = ReportsConfig <$>
        (readJSON js) <*>
        (valFromObj "fetchCount" o)

instance JSON DashboardConfig where
    showJSON = undefined
    readJSON js@(JSObject o) = DashboardConfig <$>
        (readJSON js) <*>
        (valFromObj "token" o)

instance JSON ServiceConfig where
    showJSON = undefined
    readJSON (JSObject o) = ServiceConfig <$>
        (valFromObj "url" o) <*>
        (optVal "basicAuth" o) <*>
        (optVal "proxy" o)

instance JSON AuthConfig where
    showJSON = undefined
    readJSON (JSString s) = Ok $ uncurry BasicAuth $ parseAuth s where
        parseAuth = (id *** tail) . break (==':') . fromJSString
    readJSON _ = Error "basicAuth should use the format \"user:pass\""

instance JSON ProxyConfig where
    showJSON = undefined
    readJSON (JSObject o) = ProxyConfig <$>
        (valFromObj "url" o) <*>
        (optVal "basicAuth" o)

fromOk (Ok a) = a

optVal :: JSON a => String -> JSObject JSValue -> Text.JSON.Result (Maybe a)
optVal k o = case valFromObj k o of
    Ok a -> case a of
        JSString "" -> Ok Nothing
        (JSObject o) -> case valFromObj "enabled" o of
            Ok (JSBool True) -> Just <$> readJSON a
            _ -> Ok Nothing
        o -> Just <$> readJSON o
    Error e -> Ok Nothing

getConfig :: ReportExport Config
getConfig = ReportExport return

auth :: AuthConfig -> Authority
auth (BasicAuth user pass) = AuthBasic "" user pass nullURI

proxy :: ProxyConfig -> Proxy
proxy (ProxyConfig url authCfg) = Proxy url auth' where
    auth' = auth <$> authCfg

browseService :: ServiceConfig -> BrowserAction t ()
browseService (ServiceConfig _ authCfg proxyCfg) = do
    case proxyCfg of
        Just cfg -> setProxy $ proxy $ cfg
        _        -> return ()
    case authCfg of
        Just cfg -> addAuthority $ auth $ cfg
        _        -> return ()

getURL :: ServiceConfig -> URL -> ReportExport String
getURL cfg url = ReportExport $ \_ -> do
    (uri, rsp) <- browse $ do
        browseService cfg
        request $ getRequest url
    getResponseBody $ Right rsp

postJSON :: JSON j => ServiceConfig -> URL -> j -> ReportExport ()
postJSON cfg url body = ReportExport $ \_ -> do
    let content = UTF8.fromString $ encode body
    (uri, rsp) <- browse $ do
        browseService cfg
        request $ Request
            { rqURI     = fromJust $ parseURI url
            , rqMethod  = POST
            , rqBody    = content
            , rqHeaders =
                [ Header HdrContentType "application/json"
                , Header HdrContentEncoding "utf-8"
                , Header HdrContentLength $ show $ UTF8.length content
                ]
            }
    resdata <- fmap (decode . UTF8.toString) $ getResponseBody $ Right rsp
    case resdata of
        (Ok (JSObject o)) -> case valFromObj "status" o of
            (Ok (JSString "error")) -> throw ReportError
            _ -> return ()
        _ -> throw ReportError


parseReports :: String -> [Report]
parseReports = mapj parseReport . fromOk . decode where
    mapj f (JSArray a) = map f a
    parseReport obj = Report obj $ fromOk $ parseUpdatedDate obj
    parseUpdatedDate (JSObject o) = valFromObj "updated_at" o

fmtDate :: DateString -> DateString
fmtDate s = date ++ " " ++ (init $ tail time) where
    (date, time) = break (=='T') s

fetchReports :: Maybe DateString -> ReportExport [Report]
fetchReports since = do
    (Config (ReportsConfig servCfg count) _) <- getConfig
    let (ServiceConfig url _ _) = servCfg
        url' = url ++ "/api/reports?limit_amount=" ++ show count
        time_param = case since of
            Nothing -> ""
            Just s  -> "&begin_time=" ++ (escapeURIString isUnescapedInURI s)
    fmap parseReports $ getURL servCfg (url' ++ time_param)

pushReports :: [Report] -> ReportExport ()
pushReports reports = do
    (Config _ (DashboardConfig servCfg token)) <- getConfig
    let (ServiceConfig url _ _) = servCfg
        url' = url ++ "/import/qa-reports/massupdate"
    postJSON servCfg url' $ map reportSrc reports

readSince :: ReportExport (Maybe DateString)
readSince = ReportExport $ \_ -> do
    exists <- doesFileExist sinceFilePath
    if exists
        then fmap Just $ withFile sinceFilePath ReadMode $ \h -> hGetLine h
        else return Nothing

writeSince :: DateString -> ReportExport ()
writeSince s = ReportExport $ \_ -> writeFile sinceFilePath s

main = do
    cfg <- fmap (fromOk.decode) $ readFile "config.json"
    let op = do
        reports <- fmap (fmap fmtDate) readSince >>= fetchReports
        pushReports reports
        writeSince $ reportDate $ last reports
    runRE op cfg
