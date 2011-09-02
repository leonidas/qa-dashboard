{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative
import Control.Arrow
import Control.Monad
import Data.String
import Network.Browser
import Network.HTTP
import Network.HTTP.Auth
import Network.HTTP.Proxy
import Network.URI
import Network.Stream
import Text.JSON
import Text.JSON.Pretty

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

newtype ReportExport a = ReportExport
    { runRE :: Config -> IO a }

instance Functor ReportExport where
    fmap f a = ReportExport $ fmap f . runRE a

instance Monad ReportExport where
    return  = ReportExport . const . return
    a >>= f = ReportExport $ \cfg -> do
        a' <- runRE a cfg
        runRE (f a') cfg

data Report = Report JSValue DateString

instance IsString JSString where
    fromString = toJSString

instance JSON Config where
    showJSON = undefined
    readJSON (JSObject o) = Config <$>
        (readVal "reports" o) <*>
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


{-
timeFormat = "%F %T"
formatTime = T.formatTime T.defaultTimeLocale timeFormat
parseTime  = T.readTime  T.defaultTimeLocale timeFormat
-}

maybeOk (Ok a) = Just a
maybeOk _      = Nothing

fromOk (Ok a) = a

readVal k o = valFromObj k o >>= readJSON

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

fetchURL :: ServiceConfig -> URL -> ReportExport String
fetchURL (ServiceConfig _ authCfg proxyCfg) url = ReportExport $ \cfg -> do
    (uri, rsp) <- browse $ do
        case proxyCfg of
            Just cfg -> setProxy $ proxy $ cfg
            _        -> return ()
        request $ getRequest url
    getResponseBody $ Right rsp

parseReports :: String -> [Report]
parseReports = mapj parseReport . fromOk . decode where
    mapj f (JSArray a) = map f a
    parseReport obj = Report obj $ fromOk $ parseUpdatedDate obj
    parseUpdatedDate (JSObject o) = valFromObj "updated_at" o

fetchReports :: Maybe DateString -> ReportExport [Report]
fetchReports since = do
    (Config (ReportsConfig servCfg count) _) <- getConfig
    let (ServiceConfig url _ _) = servCfg
        url' = url ++ "/api/reports?limit_amount=" ++ show count
        time_param = case since of
            Nothing -> ""
            Just s  -> "&begin_time=" ++ (escapeURIString isUnescapedInURI s)
    fmap parseReports $ fetchURL servCfg (url' ++ time_param)

