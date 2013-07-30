package fixjava.fix

import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import java.io.File
import fixjava.files.GroupFolder
import fixjava.maven.MavenParent
import fixjava.project.EclipseProject
import fixjava.project.Link
import static extension fixjava.maven.MavenPomWritter.*
import static extension fixjava.project.EclipseProjectWritter.*
import static extension fixjava.project.EclipseProjectReader.*
import fixjava.maven.MavenPom
import fixjava.maven.MavenParentPom
import com.google.common.io.Files
import java.util.ArrayList
import java.util.List

class FixMaven extends AbstractFix {
	
	override executeFix(GroupFolder groupFolder) {
		super.executeFix(groupFolder)
		
		//Create maven parent project:
		if(!groupFolder.projects.exists[pf | pf.root.name == groupFolder.parentPomName]) {
			groupFolder.createParentProject
		}
	}

	def createParentProject(GroupFolder groupFolder) {
			val project = new ProjectFolder => [
					group = groupFolder
					root = new File(groupFolder.root, groupFolder.parentPomName)
					natureCount = 1
					javaNature = false
					mavenNature = true
					useJUnit = false
			]
			groupFolder.projects.add(project)
			
			val parentMavenPom = new MavenParentPom => [
				copyright = config.copyright
				
				parent = new MavenParent => [
					groupId = config.parentGroupId
					artifactId = config.parentArtifactId
					version = "1.0.0-SNAPSHOT" //TODO: define this in config?
					relativePath = config.parentRelativePath
				]
				
				groupId = groupFolder.commonPrefix
				artifactId = groupFolder.parentPomName
				modules = groupFolder.projects.filter[pf | pf != project && pf.mavenNature].map[pf | "../" + pf.root.name].toList
			]
			createProject(project, parentMavenPom)
	}

	def createProject(ProjectFolder project, MavenParentPom mavenPom) {
			val folder = project.root
			
			//Create Project Folder
			if(!folder.exists) {
				folder.mkdir
			}
			
			//Create Project File
			val eclipseProject = project.toEclipseProject
			eclipseProject.toFile(new File(folder, ".project"))
			
			//Copy About.html file (if exists)
			val aboutFile = config.aboutFile
			if(aboutFile != null && aboutFile.exists) {
				Files::copy(aboutFile, new File(folder, "about.html"))
			}
			
			//Create POM File:
			mavenPom.toFile(new File(folder, "pom.xml"))
	}

	def toEclipseProject(ProjectFolder pf) {
		new EclipseProject => [
			name = pf.root.name
			buildCommands = #["org.eclipse.m2e.core.maven2Builder"]
			natures = #["org.eclipse.m2e.core.maven2Nature"]
			linkedResources = #["org.eclipse.core.resources.prefs", "org.eclipse.m2e.core.prefs"]
				.filter[config.linkedResourcesFiles.contains(it)]
				.map[ fileName |
						new Link =>[
							name = ".settings/" + fileName
							type = "1"
							locationURI = config.getLinkedResourcesLinkLocationURI(fileName, pf)
						]
				].toList
			]
	}
	
	override executeFix(ProjectFolder pf) {
		if(pf.javaNature) {
			//
			pf.mavenNature = true;
			
			//Create maven file:
			val mavenProject = pf.initMavenProject()
			mavenProject.packaging = pf.computePackaging
			
			mavenProject.toFile(new File(pf.root, "pom.xml"));
			
			//Fix Project File:
			val projectFile = new File(pf.root, ".project")
			val eclipseProject = projectFile.readEclipseProject
			
			eclipseProject.buildCommands = eclipseProject.buildCommands.ensureContains("org.eclipse.m2e.core.maven2Builder")
			eclipseProject.natures = eclipseProject.natures.ensureContains("org.eclipse.m2e.core.maven2Nature")
			
			val prefFileName = "org.eclipse.m2e.core.prefs"
			if(config.linkedResourcesFiles.contains(prefFileName)) {
				eclipseProject.linkedResources = eclipseProject.linkedResources.ensureContains(new Link => [
					name = ".settings/" + prefFileName
					type = "1"
					locationURI = config.getLinkedResourcesLinkLocationURI(prefFileName, pf)
				])
			}
			eclipseProject.toFile(projectFile)
		}
	}

	def <T>ensureContains(List<T> list, T element) {
		if(list.contains(element)) {
			list
		} else {
			val newList = new ArrayList()=> [
				addAll(list)
				add(element)
			]
			newList
		}
	}

	def initMavenProject(ProjectFolder pf) {
		new MavenPom => [
			copyright = config.copyright
			
			parent = new MavenParent => [
				groupId = pf.group.commonPrefix
				artifactId = pf.group.parentPomName
				version = "1.0.0-SNAPSHOT" //TODO? define this in config?
				relativePath = "../" + pf.group.parentPomName + "/"
			]
			
			artifactId = pf.root.name
		]
	}
	
	def parentPomName(GroupFolder gf) {
		gf.commonPrefix + ".parent"
	}
	
	def computePackaging(ProjectFolder pf) {
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
		<module>../«pf.root.name»</module>
		«ENDFOR»
	</modules>

	<profiles>
		<profile>
			<id>testing-build</id>
			<activation>
				<activeByDefault>true</activeByDefault>
			</activation>
			<modules>
				«FOR pf : gf.projects.filter[useJUnit]»
				<module>../«pf.root.name»</module>
				«ENDFOR»
			</modules>
		</profile>
	</profiles>
</project>
'''
	new (IConfig projectConfig) {
		super(projectConfig)
	}
}