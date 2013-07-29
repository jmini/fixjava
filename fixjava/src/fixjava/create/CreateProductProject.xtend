package fixjava.create

import static extension fixjava.maven.MavenPomWritter.*

import java.io.File
import fixjava.files.ProjectFolder
import fixjava.maven.MavenParent
import fixjava.config.IConfig
import com.google.common.base.Charsets
import com.google.common.io.Files
import java.util.regex.Pattern
import fixjava.maven.MavenProductPom

class CreateProductProject {
	
	IConfig config
	
	def void create(ProjectFolder pf, File productFile) {
		
		//Read and copy product file to the projectFolder
		if(productFile.exists) {
			val productFileCnt = Files::toString(productFile, Charsets::UTF_8)
			
			//Read
			val uid = productFileCnt.read('<product.*uid="([a-z0-9\\.]+)"')
			val launcher = productFileCnt.read('<launcher.*name="([a-z\\. ]+)"')
			val configIni = productFileCnt.read('<configIni[^>]*>(.+)</configIni>').trim
			
			val newProjectFile = new File(pf.root, productFile.name)
			val newProductFileCnt = productFileCnt.replace(configIni, pf.newConfigIniTags)
			Files::write(newProductFileCnt, newProjectFile, Charsets::UTF_8)
			
			//Copy configuration file to the projectFolder
			//TODO: for the moment there is no check that the config.ini file is called config.ini. It is possible to parse the value of configIni
			val oldConfigIni = new File(productFile.parentFile, "config.ini")
			val newConfigIni = new File(pf.root, "config.ini")
			Files::copy(oldConfigIni, newConfigIni)
			
			//Create the maven pom
			val mavenProject = new MavenProductPom => [
				copyright = config.copyright
				
				parent = new MavenParent => [
					groupId = config.getParentGroupId()
					artifactId = pf.group.commonPrefix
					version = "3.9.1-SNAPSHOT"
				]
				
				artifactId = pf.root.name
				properties = #{
					"product.id" -> uid,
					"product.outputDirectory" -> "${project.build.directory}/products/${product.id}/win32/win32/x86",
					"product.finalName" -> launcher
				}
			]
			
			val newMavenFile = new File(pf.root, "pom.xml")
			mavenProject.toFile(newMavenFile)
			
			//Create Assembly file:
			val newAssemblyFile = new File(pf.root, "assembly.xml")
			Files::write(pf.newAssemblyCnt, newAssemblyFile, Charsets::UTF_8)
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
	
	def read(String content, String regEx) {
		val pattern = Pattern::compile(regEx, Pattern::DOTALL)
		val matcher = pattern.matcher(content)
		if(matcher.find) {
			matcher.group(1)
		} else {
			throw new IllegalStateException("regEx '" + regEx + "' not found")
		}
	}

	new (IConfig projectConfig) {
		config = projectConfig
	}
}
