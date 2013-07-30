package fixjava.project

import java.io.File
import com.google.common.base.Charsets
import com.google.common.io.Files

class EclipseProjectWritter {
	def static println(EclipseProject project) {
		println(project.projectFile)
	}
	
	def static toFile(EclipseProject project, File file) {
		Files::write(project.projectFile, file, Charsets::UTF_8)
	}
	
	def static projectFile(EclipseProject project) {
		(new EclipseProjectWritter).createProjectFile(project)
	}
	
	def createProjectFile(EclipseProject p) '''
	<?xml version="1.0" encoding="UTF-8"?>
	<projectDescription>
		<name>«p.name»</name>
		<comment>«p.comment»</comment>
		<projects>
		</projects>
		<buildSpec>
			«IF !p.buildCommands.nullOrEmpty»
			«FOR buildCommand : p.buildCommands»
			<buildCommand>
				<name>«buildCommand»</name>
				<arguments>
				</arguments>
			</buildCommand>
			«ENDFOR»«ENDIF»
		</buildSpec>
		<natures>
			«IF !p.natures.nullOrEmpty»
			«FOR nature : p.natures»
			<nature>«nature»</nature>
			«ENDFOR»«ENDIF»
		</natures>
		«IF !p.linkedResources.nullOrEmpty»
		<linkedResources>
			«FOR link : p.linkedResources»
			<link>
				<name>«link.name»</name>
				<type>«link.type»</type>
				<locationURI>«link.locationURI»</locationURI>
			</link>
			«ENDFOR»
		</linkedResources>
		«ENDIF»
	</projectDescription>
	'''
}