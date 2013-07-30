package fixjava.fix

import static extension fixjava.maven.MavenPomWritter.*
import static extension fixjava.project.EclipseProjectWritter.*
import static extension fixjava.project.EclipseProjectReader.*
import static extension xtend.RegExExtensions.*

import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import java.io.File
import fixjava.files.GroupFolder
import fixjava.maven.MavenParent
import fixjava.project.EclipseProject
import fixjava.project.Link
import fixjava.maven.MavenPom
import fixjava.maven.MavenParentPom
import com.google.common.io.Files
import java.util.ArrayList
import java.util.List
import fixjava.maven.MavenProductPom
import com.google.common.base.Charsets

class FixMaven extends AbstractFix {
	
	override executeFix(GroupFolder groupFolder) {
		super.executeFix(groupFolder)
		
		//Create client product project:
		groupFolder.createUiProductProject("ui.swing")
		groupFolder.createUiProductProject("ui.swt")
		
		//Create or fix maven parent project:
		val mavenPF = groupFolder.projects.findFirst[pf | pf.root.name == groupFolder.parentPomName]
		if(mavenPF == null) {
			groupFolder.createParentProject
		} else {
			val parentPom = mavenPF.createParentPom
			mavenPF.writePom(parentPom)
		}
	}

	def createUiProductProject(GroupFolder groupFolder, String uiProjectSuffix) {
		val uiProjectFolder = groupFolder.projects.findFirst[pf | pf.root.name.endsWith(uiProjectSuffix)]
		if(uiProjectFolder != null) {
			val productFolder = new File(new File(uiProjectFolder.root, "products"), "production")
			if(productFolder.exists && productFolder.directory) {
				val productFile= productFolder.listFiles.findFirst[file | file.name.endsWith(".product")]
				if(productFile != null) {
					//Create project:
					val project = new ProjectFolder => [
						group = groupFolder
						root = new File(groupFolder.root, uiProjectFolder.root.name + ".product")
						natureCount = 1
						javaNature = false
						mavenNature = true
						useJUnit = false
					]
					groupFolder.projects.add(project)
					project.writeProject
					
					//Read current product file:
					val productFileCnt = Files::toString(productFile, Charsets::UTF_8)
					val existingUid = productFileCnt.readRegEx('<product.*uid="([a-z0-9\\.]+)"')
					val uid = existingUid ?: project.root.name
					val launcher = productFileCnt.readRegEx('<launcher.*name="([a-z\\. ]+)"')
					
					//Create Pom
					val mavenPom = project.initMavenProject(new MavenProductPom)
					mavenPom.properties = #{
						"product.id" -> uid,
						"product.outputDirectory" -> "${project.build.directory}/products/${product.id}/win32/win32/x86",
						"product.finalName" -> launcher
					}
					project.writePom(mavenPom)
					
					//TODO: for the moment there is no check that the config.ini file is called config.ini. It is possible to parse the value of configIni					
					
					//Product File:
					val newProductFile = new File(project.root, productFile.name)
					var newProductFileCnt = productFileCnt
					//--fix <product..uid attribute
					if(existingUid == null) {
						val productAttr = productFileCnt.readRegEx('(<product[^>]*) id="')
						newProductFileCnt = newProductFileCnt.replace(productAttr, productAttr + ' uid="' + uid + '"')
					}
					
					//--fix <configIni>..</configIni> content
					val configIni = productFileCnt.readRegEx('<configIni[^>]*>(.+)</configIni>').trim
					newProductFileCnt = newProductFileCnt.replace(configIni, project.newConfigIniTags)
					Files::write(newProductFileCnt, newProductFile, Charsets::UTF_8)
					productFile.delete
					
					//config.ini File:
					val oldConfigIni = new File(productFile.parentFile, "config.ini")
					val newConfigIni = new File(project.root, "config.ini")
					Files::move(oldConfigIni, newConfigIni)
					
					//Create Assembly file:
					val newAssemblyFile = new File(project.root, "assembly.xml")
					Files::write(project.newAssemblyCnt, newAssemblyFile, Charsets::UTF_8)
				}
			}
		}
	}

	def newConfigIniTags(ProjectFolder pf) '''
		<linux>/«pf.root.name»/config.ini</linux>
		      <macosx>/«pf.root.name»/config.ini</macosx>
		      <win32>/«pf.root.name»/config.ini</win32>'''
		 
	def newAssemblyCnt(ProjectFolder pf) '''
		<assembly>
		  <id>«pf.root.name».zip</id>
		  <formats>
		    <format>zip</format>
		  </formats>
		  <includeBaseDirectory>false</includeBaseDirectory>
		  <fileSets>
		    <!-- exported product files -->
		    <fileSet>
		      <directory>${product.outputDirectory}</directory>
		      <outputDirectory>/${product.finalName}</outputDirectory>
		      <excludes>
		        <exclude>p2/**</exclude>
		        <exclude>eclipsec.exe</exclude>
		        <exclude>artifacts.xml</exclude>
		      </excludes>
		    </fileSet>
		  </fileSets>
		</assembly>
	'''
	
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
			project.writeProject
			
			val parentMavenPom = project.createParentPom
			project.writePom(parentMavenPom)
	}

	def createParentPom(ProjectFolder parentProject) {
		val groupFolder = parentProject.group
		
		new MavenParentPom => [
				copyright = config.copyright
				
				parent = new MavenParent => [
					groupId = config.parentGroupId
					artifactId = config.parentArtifactId
					version = "1.0.0-SNAPSHOT" //TODO: define this in config?
					relativePath = config.parentRelativePath
				]
				
				groupId = groupFolder.commonPrefix
				artifactId = groupFolder.parentPomName
				modules = groupFolder.projects.filter[pf | pf != parentProject && pf.mavenNature].map[pf | "../" + pf.root.name].toList
			]
	}

	def toEclipseProject(ProjectFolder pf) {
		new EclipseProject => [
			name = pf.root.name
			buildCommands = #["org.eclipse.m2e.core.maven2Builder"]
			natures = #["org.eclipse.m2e.core.maven2Nature"]
			linkedResources = #["org.eclipse.core.resources.prefs", "org.eclipse.m2e.core.prefs"]
				.filter[config.linkedResourcesFiles.contains(it)]
				.map[ fileName |
						new Link(
							".settings/" + fileName,
							"1",
							config.getLinkedResourcesLinkLocationURI(fileName, pf)
						)
				].toList
			]
	}
	
	
	def writeProject(ProjectFolder project) {
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
	}
	
	def writePom(ProjectFolder project, MavenPom mavenPom) {
		//Create POM File:
		mavenPom.toFile(new File(project.root, "pom.xml"))
	}
	
	override executeFix(ProjectFolder pf) {
		if(pf.javaNature) {
			//
			pf.mavenNature = true;
			
			//Create maven file:
			val mavenProject = pf.initMavenProject(new MavenPom)
			mavenProject.packaging = pf.computePackaging
			
			mavenProject.toFile(new File(pf.root, "pom.xml"));
			
			//Fix Project File:
			val projectFile = new File(pf.root, ".project")
			val eclipseProject = projectFile.readEclipseProject
			
			eclipseProject.buildCommands = eclipseProject.buildCommands.ensureContains("org.eclipse.m2e.core.maven2Builder")
			eclipseProject.natures = eclipseProject.natures.ensureContains("org.eclipse.m2e.core.maven2Nature")
			
			val prefFileName = "org.eclipse.m2e.core.prefs"
			if(config.linkedResourcesFiles.contains(prefFileName)) {
				eclipseProject.linkedResources = eclipseProject.linkedResources.ensureContains(new Link(
					".settings/" + prefFileName,
					"1",
					config.getLinkedResourcesLinkLocationURI(prefFileName, pf)
				))
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

	def initMavenProject(ProjectFolder pf, MavenPom mavenPom) {
		mavenPom => [
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