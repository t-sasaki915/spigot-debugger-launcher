module Minecraft.Server.Spigot.SpigotSetup (setupSpigot) where

import           AppState
import           CrossPlatform                (curlExecName, javaExecName)
import           FileIO
import           ProcessIO

import           Data.Minecraft.MCServerBrand (MCServerBrand (Spigot),
                                               getMCServerExecutableName)
import           System.FilePath              ((</>))

makeNecessaryDirectories :: AppStateIO ()
makeNecessaryDirectories = do
    buildDir <- getBuildDir

    makeDirectory buildDir $
        "Failed to make a directory '" ++ buildDir ++ "'"

downloadBuildTools :: AppStateIO ()
downloadBuildTools = do
    buildDir <- getBuildDir

    putStrLn' "Downloading BuildTools..."

    let buildToolsUrl = "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
        downloadPath  = buildDir </> "BuildTools.jar"

    execProcess curlExecName ["-L", "-o", downloadPath, buildToolsUrl] buildDir
        "Failed to execute curl that was to download BuildTools" >>=
            expectExitSuccess
                "Failed to download BuildTools"

useBuildTools :: AppStateIO ()
useBuildTools = do
    serverVersion  <- getServerVersion
    buildDir       <- getBuildDir

    putStrLn' "Building a Spigot Server... This will take some minutes."

    let buildToolsPath = buildDir </> "BuildTools.jar"

    execProcess javaExecName ["-jar", buildToolsPath, "--rev", show serverVersion] buildDir
        "Failed to execute java that was to build a Spigot server" >>=
            expectExitSuccess
                "Failed to build a Spigot server"

adoptServerJar :: AppStateIO ()
adoptServerJar = do
    workingDir    <- getWorkingDir
    buildDir      <- getBuildDir
    serverVersion <- getServerVersion

    let copyPath      = workingDir </> getMCServerExecutableName Spigot serverVersion
        serverJarPath = buildDir </> ("spigot-" ++ show serverVersion ++ ".jar")

    copyFile' serverJarPath copyPath $
        "Failed to copy '" ++ serverJarPath ++ "' to '" ++ copyPath ++ "'"

setupSpigot :: AppStateIO ()
setupSpigot = do
    makeNecessaryDirectories
    downloadBuildTools
    useBuildTools
    adoptServerJar
