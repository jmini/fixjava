package fixjava.project

import static extension fixjava.project.EclipseProjectWritter.*
import static org.junit.Assert.*;

import org.junit.Test;


class EclipseProjectWritterTest {
	
	@Test
	def testProject1() {
		val p = new EclipseProject => [
			name = "myproject"
		]
		val expected = '''
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
		assertEquals(expected , p.projectFile.toString)  
	}
	
	@Test
	def testProject2() {
		val p = new EclipseProject => [
			name = "myproject"
			buildCommands = #["org.eclipse.m2e.core.maven2Builder"]
			natures = #["org.eclipse.m2e.core.maven2Nature"]
			linkedResources = #[
				new Link(
					".settings/org.eclipse.core.resources.prefs",
					"1",
					"PARENT-2-PROJECT_LOC/com.bsiag.tools.rt-feature/.settings/org.eclipse.core.resources.prefs"
				),
				new Link(
					".settings/org.eclipse.m2e.core.prefs",
					"1",
					"PARENT-2-PROJECT_LOC/com.bsiag.tools.rt-feature/.settings/org.eclipse.m2e.core.prefs"
				)
			]
		]
		val expected = '''
		<?xml version="1.0" encoding="UTF-8"?>
		<projectDescription>
			<name>myproject</name>
			<comment></comment>
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
		assertEquals(expected , p.projectFile.toString)  
	}
}