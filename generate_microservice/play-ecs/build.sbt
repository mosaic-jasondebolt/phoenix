
maintainer:= "Jason DeBolt"

dockerExposedPorts in Docker := Seq(9000, 9443)

name := """docker-pipeline-demo"""

// DO NOT CHANGE THIS!!! The build system will replace IMAGE_TAG with correct the first part of the commit SHA-1.
version := "IMAGE_TAG"

lazy val root = (project in file(".")).enablePlugins(PlayJava)

scalaVersion := "2.12.4"

crossScalaVersions := Seq("2.11.12", "2.12.4")

testOptions in Test := Seq(Tests.Argument(TestFrameworks.JUnit, "-a", "-v"))

libraryDependencies += guice

dockerRepository := Some("057281004471.dkr.ecr.us-east-1.amazonaws.com")
