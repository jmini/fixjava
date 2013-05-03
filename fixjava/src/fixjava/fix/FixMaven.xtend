package fixjava.fix

import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import com.google.common.io.Files
import com.google.common.base.Charsets
import java.io.File

class FixMaven extends AbstractFix {
	
	override executeFix(ProjectFolder pf) {
		if(pf.mavenNature) {
			if(pf.javaNature) {
				pf.createMavenPomFile.writeToPomFile(pf)
			}
		}
	}
	
	def createMavenPomFile(ProjectFolder pf) 
'''
<?xml version="1.0" encoding="UTF-8"?>
<project
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"
	xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<modelVersion>4.0.0</modelVersion>

	<parent>
		<groupId>«pf.group.commonPrefix»</groupId>
		<artifactId>«pf.group.commonPrefix».parent</artifactId>
		<version>1.0.0-SNAPSHOT</version>
		<relativePath>../«pf.group.commonPrefix».parent/</relativePath>
	</parent>

	<artifactId>«pf.root.name»</artifactId>
	<packaging>«pf.packaging»</packaging>
</project>
'''
	
	def getPackaging(ProjectFolder pf) {
		if(pf.useJUnit) {
			"eclipse-test-plugin"
		} else {
			"eclipse-plugin"
		}
	}
	
	def writeToPomFile(CharSequence pomFileCnt, ProjectFolder pf) {
		val pomFile = new File(pf.root, "pom.xml")
		Files::write(pomFileCnt, pomFile, Charsets::UTF_8)
	}
	
	new (IConfig projectConfig) {
		super(projectConfig)
	}
}