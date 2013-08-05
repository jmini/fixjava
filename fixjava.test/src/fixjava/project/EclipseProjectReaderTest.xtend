package fixjava.project

import static extension fixjava.project.EclipseProjectWritter.*
import static org.junit.Assert.*;
import org.junit.Test
import static extension fixjava.project.EclipseProjectReader.*

class EclipseProjectReaderTest {
	
	@Test
	def testProject1ReadWrite() {
		val projectContent = '''
		<?xml version="1.0" encoding="UTF-8"?>
		<projectDescription>
			<name>myproject</name>
			<comment></comment>
			<projects>
			</projects>
			<buildSpec>
			</buildSpec>
			<natures>
			</natures>
		</projectDescription>
		'''
		
		val p = projectContent.readEclipseProject
		
		assertEquals(projectContent, p.projectFile.toString)  
	}
	
	@Test
	def testProject2ReadWrite() {
		val projectContent = '''
		<?xml version="1.0" encoding="UTF-8"?>
		<projectDescription>
			<name>myproject</name>
			<comment>My Comment</comment>
			<projects>
			</projects>
			<buildSpec>
				<buildCommand>
					<name>org.eclipse.m2e.core.maven2Builder</name>
					<arguments>
					</arguments>
				</buildCommand>
			</buildSpec>
			<natures>
				<nature>org.eclipse.m2e.core.maven2Nature</nature>
			</natures>
			<linkedResources>
				<link>
					<name>.settings/org.eclipse.core.resources.prefs</name>
					<type>1</type>
					<locationURI>PARENT-2-PROJECT_LOC/com.bsiag.tools.rt-feature/.settings/org.eclipse.core.resources.prefs</locationURI>
				</link>
				<link>
					<name>.settings/org.eclipse.m2e.core.prefs</name>
					<type>1</type>
					<locationURI>PARENT-2-PROJECT_LOC/com.bsiag.tools.rt-feature/.settings/org.eclipse.m2e.core.prefs</locationURI>
				</link>
			</linkedResources>
		</projectDescription>
		'''
		
		val p = projectContent.readEclipseProject
		
		assertEquals(projectContent, p.projectFile.toString)  
	}
}