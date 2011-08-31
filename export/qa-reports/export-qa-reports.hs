
import Control.Monad
import Network.HTTP
import Network.Stream
import Text.JSON

type URL = String

data Config          = Config ReportsConfig DashboardConfig
data ServiceConfig   = ServiceConfig URL (Maybe AuthConfig) (Maybe ProxyConfig)
data ReportsConfig   = ReportsConfig ServiceConfig FetchCount
type DashboardConfig = ServiceConfig
data AuthConfig      = BasicAuth Username Password | TokenAuth Token
data ProxyConfig     = ProxyConfig URL (Maybe AuthConfig)

type FetchCount = Int
type Username   = String
type Password   = String
type Token      = String

newtype ReportExport a = ReportExport
    { runRE :: Config -> IO a }

instance Monad ReportExport where
    return  = ReportExport . const . return
    a >>= f = ReportExport $ \cfg -> do
        a' <- runRE a cfg
        runRE (f a') cfg

getConfig :: ReportExport Config
getConfig = ReportExport return

proxy :: ProxyConfig -> Proxy
proxy (ProxyConfig url auth) = Proxy url auth' where
    auth' = case auth of
        Nothing -> Nothing
        Just (AuthConfig)

fetchURL :: ServiceConfig -> URL -> ReportExport String
fetchURL = ReportExport $ do
    rsp <- browse $ do
        setProxy $ Proxy
