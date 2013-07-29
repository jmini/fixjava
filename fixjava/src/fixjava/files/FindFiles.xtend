package fixjava.files

import java.io.File
import java.util.ArrayList
import java.util.List

import static extension fixjava.files.XmlExtensions.*
import java.util.LinkedHashSet
import com.google.common.collect.Lists
import com.google.common.io.Files
import com.google.common.base.Charsets

class FindFiles {
	def List<GroupFolder> findProjects(File folder, int depth) {
		val allProjects = findProjectsRec(folder, depth)
		
		val folders = allProjects.map[it.pf.root.parentFile].removeDuplicate
		val groups = folders.map[it.createGroupFolder(allProjects)]
		
		return groups
	}

	def createGroupFolder(File parentFolder, List<P_ProjectFolder> allProjects) {
		val projects = allProjects.filter[it.pf.root.absolutePath.startsWith(parentFolder.absolutePath)]
		val commonPrefix = projects.map[it.pf].findCommonPrefix.removeTrailingPoint
		
		val group = new GroupFolder
		group.root = parentFolder
		group.projects = Lists::newArrayList(projects.map[it.pf])
		group.commonPrefix = commonPrefix
		
		val min = projects.map[it.depth].reduce[i1, i2| Math::min(i1, i2)]
		val max = projects.map[it.depth].reduce[i1, i2| Math::max(i1, i2)]
		if(min != max) {
			throw new IllegalStateException("min <"+min+"> and max <"+max+"> are expected to be the same")
		}
		group.depth = min
		
		group.projects.forEach[it.group = group]
		return group
	}
	
	def List<P_ProjectFolder> findProjectsRec(File folder, int depth) {
		val list = new ArrayList<P_ProjectFolder>()
		
		//Find the setting file:
		list.addAll (
			folder
				.listFiles[File f| return f.name == ".project"]
				.map[File f | f.createProjectFile(depth) ]
			)
		
		//Look in child folders:
		folder
			.listFiles[File f| return f.isDirectory]
			.forEach[list.addAll (findProjectsRec(depth+1))]
		
		return list;
	}
	
	def <T> removeDuplicate(List<T> list) {
		return new ArrayList<T>(new LinkedHashSet<T>(list)); 
	}
	
	def P_ProjectFolder createProjectFile(File projectFile, int depth) {
		val projectFolder = projectFile.parentFile
		val pf = new ProjectFolder()
		pf.root = projectFolder
		
		//Read .project file:
		val doc = projectFile.toDocument;
		val natures = doc.selectByXPathQuery("/projectDescription/natures/nature");
		pf.natureCount = natures.size
		pf.javaNature = !natures.filter["org.eclipse.jdt.core.javanature" == it.textContent].empty
		pf.mavenNature = !natures.filter["org.eclipse.m2e.core.maven2Nature" == it.textContent].empty
		
		//Read MANIFEST.MF file
		val manifestFile = new File(new File(projectFolder, "META-INF"), "MANIFEST.MF")
		if(manifestFile.exists) {
			val manifestCnt = Files::toString(manifestFile, Charsets::UTF_8)
			pf.useJUnit = manifestCnt.contains("org.junit")
		}
		
		new P_ProjectFolder => [
			it.pf = pf
			it.depth = depth
		]
	}
	
	def String findCommonPrefix(Iterable<ProjectFolder> list) {
		if(list.empty) {
			return ""
		} else {
			val names = list.map[root.name]
			return names.reduce[n1, n2| commonPrefix(n1, n2)]
		}
	}
	
	//NICE: this is included in Guava (version >11) as Strings::commonPrefix
	def static String commonPrefix(String a, String b) {
		val maxPrefixLength = Math::min(a.length, b.length)
		var p = 0
		while (p < maxPrefixLength && a.charAt(p) == b.charAt(p)) {
			p = p + 1
		}
		a.substring(0, p)
	}
	
	def removeTrailingPoint(String string) {
		return if(string.endsWith(".")) {
			string.substring(0, string.length -1)
		} else {
			string
		}
	}
}

class P_ProjectFolder {
	@Property ProjectFolder pf
	@Property int depth
}