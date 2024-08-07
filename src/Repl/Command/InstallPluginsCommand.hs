{-# OPTIONS_GHC -Wno-partial-fields #-}

module Repl.Command.InstallPluginsCommand (InstallPluginsCommand(InstallPluginsCommand)) where

import           Imports

import           AppState
import           Minecraft.Server.PluginInstaller
import           Repl.Command.StartServerCommand
import           Repl.Command.TerminateServerCommand
import           Repl.ReplCommand                    (ReplCommand (..))

import           Options.Applicative

data InstallPluginsCommand = InstallPluginsCommand
                           | InstallPluginsCommandOptions
                                { dynamicPluginsOnly :: Bool
                                , staticPluginsOnly  :: Bool
                                , andRestart         :: Bool
                                , withoutAsk         :: Bool
                                }

instance ReplCommand InstallPluginsCommand where
    cmdDescription = const "Install plugins to the server."

    cmdArgParser = const installPluginsCommandArgParser

    cmdProcedure = installPluginsCommandProcedure

installPluginsCommandArgParser :: AppStateIO (Parser InstallPluginsCommand)
installPluginsCommandArgParser =
    return $
        InstallPluginsCommandOptions
            <$> switch
                ( long "dynamicOnly"
               <> short 'd'
               <> help "Install only dynamic plugins."
                )
            <*> switch
                ( long "staticOnly"
               <> short 's'
               <> help "Install only static plugins."
                )
            <*> switch
                ( long "restart"
               <> short 'r'
               <> help "Restart the Minecraft server after installation."
                )
            <*> switch
                ( long "force"
               <> short 'f'
               <> help "Restart the Minecraft server without confirming."
                )

installPluginsCommandProcedure :: InstallPluginsCommand -> AppStateIO ()
installPluginsCommandProcedure opts = do
    let dynamicOnly = dynamicPluginsOnly opts
        staticOnly  = staticPluginsOnly opts
        restart     = andRestart opts
        force       = withoutAsk opts

    when (dynamicOnly && staticOnly) $
        error "Please do not specify both '--dynamicOnly' and '--staticOnly' at the same time."

    updateServerProc

    whenM (getServerProc <&> isJust) $ do
        unless restart $
            error "The Minecraft server is running. Please stop it first. Or you can use '--restart' option."

        executeReplCommandInternal TerminateServerCommand ["--force" | force]

    removeUnusedPlugins

    unless staticOnly
        installDynamicPlugins

    unless dynamicOnly
        installStaticPlugins

    putStrLn' "Successfully installed plugins."

    when restart $
        executeReplCommandInternal StartServerCommand []
