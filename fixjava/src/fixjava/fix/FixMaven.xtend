package fixjava.fix

import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import com.google.common.io.Files
import com.google.common.base.Charsets
import java.io.File
import fixjava.files.GroupFolder

class FixMaven extends AbstractFix {
	
	override executeFix(GroupFolder groupFolder) {
		super.executeFix(groupFolder)
		
		//Create maven parent project
		
	}
	
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
	
	def createMavenParentPom(GroupFolder gf) '''
<?xml version="1.0" encoding="UTF-8"?>
<project
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"
	xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<modelVersion>4.0.0</modelVersion>

	<parent>
		<groupId>org.eclipsescout.demo</groupId>
		<artifactId>org.eclipsescout.demo.master</artifactId>
		<version>1.0.0-SNAPSHOT</version>
		<relativePath>../../build/org.eclipsescout.demo.master/</relativePath>
	</parent>

	<groupId>«gf.commonPrefix»</groupId>
	<artifactId>«gf.commonPrefix».parent</artifactId>
	<packaging>pom</packaging>

	<modules>
		«FOR pf : gf.projects»
		<module>../org.eclipsescout.demo.minifigcreator.client</module>
		<module>../org.eclipsescout.demo.minifigcreator.server</module>
		<module>../org.eclipsescout.demo.minifigcreator.shared</module>
		<module>../org.eclipsescout.demo.minifigcreator.ui.swing</module>
		<module>../org.eclipsescout.demo.minifigcreator.ui.swt</module>

		<!-- <module>../org.eclipsescout.demo.minifigcreator.server.product</module> -->
		<!-- <module>../org.eclipsescout.demo.minifigcreator.server.product.war</module> -->
		<!-- <module>../org.eclipsescout.demo.minifigcreator.ui.swing.product</module> -->
		«ENDFOR»
	</modules>

	<profiles>
		<profile>
			<id>testing-build</id>
			<activation>
				<activeByDefault>true</activeByDefault>
			</activation>
			<modules>
				<module>../org.eclipsescout.demo.minifigcreator.client.test</module>
				<module>../org.eclipsescout.demo.minifigcreator.server.test</module>
				<module>../org.eclipsescout.demo.minifigcreator.shared.test</module>
			</modules>
		</profile>
	</profiles>
</project>
'''
	
	def writeToPomFile(CharSequence pomFileCnt, ProjectFolder pf) {
		val pomFile = new File(pf.root, "pom.xml")
		Files::write(pomFileCnt, pomFile, Charsets::UTF_8)
	}
	
	new (IConfig projectConfig) {
		super(projectConfig)
	}
}