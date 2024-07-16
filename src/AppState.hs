{-# OPTIONS_GHC -Wno-missing-export-lists #-}

module AppState where

import           CLIOptions.CLIOptions            (CLIOptions (..))
import           CLIOptions.Parser                (parseCLIOptions)
import           Config.Config
import           Config.Loader                    (loadConfig)
import           Minecraft.MinecraftVersion       (MinecraftVersion)

import           Control.Monad.Trans.Class        (lift)
import           Control.Monad.Trans.Except       (ExceptT)
import           Control.Monad.Trans.State.Strict (StateT, get)
import           Data.Functor                     ((<&>))
import           System.Directory                 (makeAbsolute)
import           System.FilePath                  ((</>))

type AppStateIO = ExceptT String (StateT AppState IO)

data AppState = AppState
    { cliOptions :: CLIOptions
    , config     :: Config
    }
    deriving Show

initialState :: IO AppState
initialState = do
    cliOpts <- parseCLIOptions
    conf    <- loadConfig (configFile cliOpts)

    let constructor = AppState
    return (constructor cliOpts conf)

absolutePath :: FilePath -> AppStateIO FilePath
absolutePath = lift . lift . makeAbsolute

getWorkingDir :: AppStateIO FilePath
getWorkingDir = lift get >>=
    absolutePath . workingDir . applicationConfig . config

getClientWorkingDir :: AppStateIO FilePath
getClientWorkingDir = getWorkingDir <&> (</> "client")

getBuildDir :: AppStateIO FilePath
getBuildDir = getWorkingDir <&> (</> "build")

getBuildToolsPath :: AppStateIO FilePath
getBuildToolsPath = getBuildDir <&> (</> "BuildTools.jar")

getMinecraftDir :: AppStateIO FilePath
getMinecraftDir = lift get >>=
    absolutePath . minecraftDir . cliOptions

getMinecraftAssetsDir :: AppStateIO FilePath
getMinecraftAssetsDir = getMinecraftDir <&> (</> "assets")

getMinecraftLibrariesDir :: AppStateIO FilePath
getMinecraftLibrariesDir = getMinecraftDir <&> (</> "libraries")

getMinecraftVersionsDir :: AppStateIO FilePath
getMinecraftVersionsDir = getMinecraftDir <&> (</> "versions")

getServerVersion :: AppStateIO MinecraftVersion
getServerVersion = lift get <&> (serverVersion . serverConfig . config)

getServerJarPath :: AppStateIO FilePath
getServerJarPath = getServerVersion >>= \ver ->
    getWorkingDir <&> (</> "spigot-" ++ show ver ++ ".jar")

getTemporaryServerJarPath :: AppStateIO FilePath
getTemporaryServerJarPath = getServerVersion >>= \ver ->
    getBuildDir <&> (</> "spigot-" ++ show ver ++ ".jar")
