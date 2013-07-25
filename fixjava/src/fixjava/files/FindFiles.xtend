package fixjava.files

import java.io.File
import java.util.ArrayList
import java.util.List

import static extension fixjava.files.XmlExtensions.*
import java.util.LinkedHashSet
import com.google.common.collect.Lists

class FindFiles {
	def List<GroupFolder> findProjects(File folder, int depth) {
		val allProjects = findProjectsRec(folder, depth)
		
		val folders = allProjects.map[it.root.parentFile].removeDuplicate
		val groups = folders.map[it.createGroupFolder(allProjects)]
		
		return groups
	}

	def createGroupFolder(File parentFolder, List<ProjectFolder> allProjects) {
		val projects = allProjects.filter[it.root.absolutePath.startsWith(parentFolder.absolutePath)]
		val commonPrefix = projects.findCommonPrefix.removeTrailingPoint
		
		val group = new GroupFolder
		group.root = parentFolder
		group.projects = Lists::newArrayList(projects)
		group.commonPrefix = commonPrefix
		
		projects.forEach[it.group = group]
		
		return group
	}
	
	def List<ProjectFolder> findProjectsRec(File folder, int depth) {
		val list = new ArrayList<ProjectFolder>()
		
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
	
	def createProjectFile(File projectFile, int depth) {
		val projectFolder = projectFile.parentFile
		val pf = new ProjectFolder()
		pf.root = projectFolder
		pf.depth = depth
		
		//Read .project file:
		val doc = projectFile.toDocument;
		val natures = doc.selectByXPathQuery("/projectDescription/natures/nature");
		pf.natureCount = natures.size
		pf.javaNature = !natures.filter["org.eclipse.jdt.core.javanature" == it.textContent].empty
		pf.mavenNature = !natures.filter["org.eclipse.m2e.core.maven2Nature" == it.textContent].empty
		
		return pf
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