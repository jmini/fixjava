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
import java.util.HashMap
import java.util.Map

class FixMaven extends AbstractFix {
	val SERVER_ADDITIONAL_PROPERTIES = #{"product.web-inf.templateDirectory" -> config.webInfTemplateDirectoy}
	
	override executeFix(GroupFolder groupFolder) {
		super.executeFix(groupFolder)
		
		//Create client product project:
		groupFolder.createClientUiProductProject("ui.swing")
		groupFolder.createClientUiProductProject("ui.swt")
		groupFolder.createServerProductProject
		groupFolder.createServerUiProductProject("ui.rap")
		
		//Create or fix maven parent project:
		val mavenPF = groupFolder.projects.findFirst[pf | pf.root.name == groupFolder.parentProjectName]
		if(mavenPF == null) {
			groupFolder.createParentProject
		} else {
			val parentPom = mavenPF.createParentPom
			mavenPF.writePom(parentPom)
		}
	}

	/**
	 * For server project
	 */
	def createServerProductProject(GroupFolder groupFolder) {
		createProductProject(groupFolder, "server", SERVER_ADDITIONAL_PROPERTIES, false, "_server")
	}
	
	/**
	 * For rap product project
	 */
	def createServerUiProductProject(GroupFolder groupFolder, String uiProjectSuffix) {
		createProductProject(groupFolder, uiProjectSuffix, SERVER_ADDITIONAL_PROPERTIES, false, "")
	}
	
	/**
	 * For swt, swing product project
	 */
	def createClientUiProductProject(GroupFolder groupFolder, String uiProjectSuffix) {
		createProductProject(groupFolder, uiProjectSuffix, new HashMap<String, String>, true, "")
	}
	
	def createProductProject(GroupFolder groupFolder, String projectSuffix, Map<String,String> additionalProperties, boolean client, String finalNameSuffix) {
		val targetPF = groupFolder.projects.findFirst[pf | pf.root.name.endsWith(projectSuffix)]
		if(targetPF != null) {
			val productFolder = new File(new File(targetPF.root, "products"), "production")
			val existing = if(productFolder.exists && productFolder.directory) {
				val productFile= productFolder.listFiles.findFirst[file | file.name.endsWith(".product")]
				if(productFile != null) {
					//Create project:
					val project = new ProjectFolder => [
						group = groupFolder
						root = new File(groupFolder.root, targetPF.productProjectName)
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
					new P_productAndUid(project, uid)
				} else {
					targetPF.findExistingProjectAndUid
				}
			} else {
				targetPF.findExistingProjectAndUid
			}
			val project = existing.project
			
			//Create or Update pom.xml
			val mavenPom = project.initMavenProject(new MavenProductPom)
			mavenPom.properties = new HashMap<String,String>
			mavenPom.properties.putAll(#{
				"product.id" -> existing.uid,
				"product.outputDirectory" -> "${project.build.directory}/products/${product.id}/win32/win32/x86",
				"product.finalName" -> groupFolder.alias + finalNameSuffix
			})
			mavenPom.properties.putAll(additionalProperties)
			project.writePom(mavenPom)
			
			//Create or update assembly.xml file:
			val newAssemblyFile = new File(project.root, "assembly.xml")
			val newAssemblyCnt = if(client) { project.newClientAssemblyCnt } else { project.newServerAssemblyCnt }
			Files::write(newAssemblyCnt, newAssemblyFile, Charsets::UTF_8)
			
		}
	}

	def findExistingProjectAndUid(ProjectFolder targetPF) {
		//Try to find the corresponding existing product project
		val project = targetPF.group.projects.findFirst[pf | pf.root.name == targetPF.productProjectName]
		if(project == null) {
			throw new IllegalStateException("Was expecting a project with name ")
		}
		
		val existingProductFile= project.root.listFiles.findFirst[file | file.name.endsWith(".product")]
		if(existingProductFile == null) {
			throw new IllegalStateException("Was expecting a .product file in the "+project.root.name+" project")
		}
		val productFileCnt = Files::toString(existingProductFile, Charsets::UTF_8)
		
		val uid = productFileCnt.readRegEx('<product.*uid="([a-z0-9\\.]+)"')
		if(uid == null) {
			throw new IllegalStateException("Was expecting a uid attribute in product tag in the file in the "+existingProductFile.name+" file")
		}
		new P_productAndUid(project, uid)
	}

	def productProjectName(ProjectFolder targetPF) {
		targetPF.root.name + ".product"
	}

	def alias(GroupFolder groupFolder) { 
		groupFolder.commonPrefix.split("\\.").last
	}

	def newConfigIniTags(ProjectFolder pf) '''
		<linux>/«pf.root.name»/config.ini</linux>
		      <macosx>/«pf.root.name»/config.ini</macosx>
		      <win32>/«pf.root.name»/config.ini</win32>'''
		 
	def newClientAssemblyCnt(ProjectFolder pf) '''
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
	
	def newServerAssemblyCnt(ProjectFolder pf) '''
		<assembly>
		  <id>«pf.root.name».war</id>
		  <formats>
		    <format>war</format>
		  </formats>
		  <includeBaseDirectory>false</includeBaseDirectory>
		  <fileSets>
		    <!-- web-inf template -->
		    <fileSet>
		      <directory>${product.web-inf.templateDirectory}</directory>
		      <outputDirectory>/WEB-INF</outputDirectory>
		      <includes>
		        <include>**</include>
		      </includes>
		    </fileSet>
		 
		    <!-- exported product files -->
		    <fileSet>
		      <directory>${product.outputDirectory}</directory>
		      <outputDirectory>/WEB-INF/eclipse</outputDirectory>
		      <includes>
		        <include>configuration/**</include>
		        <include>plugins/**</include>
		      </includes>
		    </fileSet>
		  </fileSets>
		</assembly>
	'''
	
	def createParentProject(GroupFolder groupFolder) {
			val project = new ProjectFolder => [
					group = groupFolder
					root = new File(groupFolder.root, groupFolder.parentProjectName)
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
				artifactId = groupFolder.parentProjectName
				name = parentProject.pomName
				
				modules = groupFolder.projects.filter[pf | pf != parentProject && pf.mavenNature].map[pf | "../" + pf.root.name].sort.toList
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
				artifactId = pf.group.parentProjectName
				version = "1.0.0-SNAPSHOT" //TODO? define this in config?
				relativePath = "../" + pf.group.parentProjectName + "/"
			]
			
			artifactId = pf.root.name
			name = pf.pomName
		]
	}
	
	def parentProjectName(GroupFolder gf) {
		gf.commonPrefix + ".parent"
	}

	def pomName(ProjectFolder pf) {
		pf.group.alias + " - " + pf.root.name.replace(pf.group.commonPrefix + ".", "")
	}

	def computePackaging(ProjectFolder pf) {
		if(pf.useJUnit) {
			"eclipse-test-plugin"
		} else {
			"eclipse-plugin"
		}
	}

	new (IConfig projectConfig) {
		super(projectConfig)
	}
	
}
/**
 * Structure that contains a project and the uid (== product uid attribute)
 */
@Data class P_productAndUid {
	ProjectFolder project
	String uid
}