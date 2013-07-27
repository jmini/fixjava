package fixjava.maven

import java.io.File
import java.util.Map
import com.google.common.io.Files
import com.google.common.base.Charsets

class MavenPom {
	
	def static println(MavenProject project) {
		println(project.pom)
	}
	
	def static toFile(MavenProject project, File file) {
		Files::write(project.pom, file, Charsets::UTF_8)
	}
	
	def static pom(MavenProject project) {
		(new MavenPom).createPom(project)
	}
	
	def createPom(MavenProject project) '''
		<?xml version="1.0" encoding="UTF-8"?>
		«project.copyright?.outCopyright»
		<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns="http://maven.apache.org/POM/4.0.0"
		    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
		  «outTag("4.0.0", "modelVersion")»
		
		  «project.parent?.outParent»
		  «project.artifactId?.outTag("artifactId")»
		  «project.packaging?.outTag("packaging")»
		  «project.name?.outTag("name")»
		
		  «project.properties?.outProperties»
		
		  «project.pomBody»
		</project>
		'''
	
	def outCopyright(String copyright) '''
		<!--
		  «copyright»
		-->
		
	'''

	def outParent(MavenParent parent) '''
		<parent>
		  «parent.groupId?.outTag("groupId")»
		  «parent.artifactId?.outTag("artifactId")»
		  «parent.version?.outTag("version")»
		</parent>
		
		'''
	
	def outTag(String content, String tag) '''<«tag»>«content»</«tag»>'''
	
	def outProperties(Map<String,String> map) {
		if(!map.empty) {
			'''
			<properties>
			«FOR e : map.entrySet»  «e.value?.outTag(e.key)»
			«ENDFOR»
			</properties>
			'''
		}
	}
}