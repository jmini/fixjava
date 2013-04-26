package fixjava.files

import java.io.File
import java.util.ArrayList
import java.util.List

import static extension fixjava.files.XmlExtensions.*
import java.util.LinkedHashSet

class FindFiles {
	def List<ProjectFolder> findProjects(File folder, int depth) {
		val list = findProjectsRec(folder, depth)
		
		val folders = list.map[it.root.parentFile].removeDuplicate
		folders.forEach[parentFolder |
			val children = list.filter[it.root.absolutePath.startsWith(parentFolder.absolutePath)]
			val commonPrefix = children.findCommonPrefix
			children.forEach[it.commonPrefix = commonPrefix]
		]
		return list
	}
	
	def <T> removeDuplicate(List<T> list) {
		return new ArrayList<T>(new LinkedHashSet<T>(list)); 
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
	
	def createProjectFile(File file, int depth) {
		val pf = new ProjectFolder()
		pf.root = file.parentFile
		pf.depth = depth
		
		
		/*
		val doc = file.toDocument;
		val nodes = doc.selectByXPathQuery("/projectDescription/natures/*")
		pf.natureCount = nodes.size
		* [text="org.eclipse.jdt.core.javanature"]
		 */
		val doc = file.toDocument;
		val natures = doc.selectByXPathQuery("/projectDescription/natures/nature");
		pf.natureCount = natures.size
		pf.javaNature = !natures.filter["org.eclipse.jdt.core.javanature" == it.textContent].empty
		pf.mavenNature = !natures.filter["org.eclipse.m2e.core.prefs" == it.textContent].empty
		
		return pf
	}
	
	def String findCommonPrefix(Iterable<ProjectFolder> list) {
		if(list.size == 0) {
			return "";
		}
		val names = list.map[root.name]
		val firstName = names.findFirst[true]
		
		for(int p: 1..firstName.length) {
			if(!names.forall[it.length >= p && it.substring(0, p) == firstName.substring(0, p)]) {
				return firstName.substring(0, p-1)
			}
		}
		
		return firstName;
	}
}