package fixjava.fix

import fixjava.files.ProjectFolder
import fixjava.config.IConfig
import java.io.File
import com.google.common.base.CharMatcher
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardCopyOption
import java.nio.file.Path
import java.nio.file.SimpleFileVisitor
import java.nio.file.attribute.BasicFileAttributes
import java.io.IOException
import java.nio.file.FileVisitResult
import java.util.List
import java.util.ArrayList
import com.google.common.base.Charsets
import fixjava.files.GroupFolder

/**
 * Fix the bundle symbolic name (and if there is a change, for java project the main package)
 */
class FixBSN extends AbstractFix {
	
	String oldNamePrefix
	String newNamePrefix

	override executeFix(GroupFolder gf) {
		oldNamePrefix = gf.commonPrefix
		newNamePrefix = config.getBSNNewNamePrefix(gf)
			
		super.executeFix(gf)
		
		gf.commonPrefix = newNamePrefix
	}
	
	override executeFix(ProjectFolder pf) {
		if(pf.group.depth == config.BSNExpectedDepth) {
			val oldBSN = pf.root.name
			val newBSN = newNamePrefix + oldBSN.substring(oldNamePrefix.length)
			
//			println(oldBSN + " > "+ newBSN)
//			println(oldNamePrefix + " > "+ newNamePrefix)
//			println("---")
			
			if(newBSN != oldBSN) {
				//Move the root folder
				val newRoot = new File(pf.root.parentFile, newBSN)
				pf.root.moveTo(newRoot)
				pf.root = newRoot
				
				if(pf.javaNature) {
					val oldRootSrcPackage = newRoot.createRootSrcPackage(oldBSN)
					if(oldRootSrcPackage.exists) {
						val newRootSrcPackage = newRoot.createRootSrcPackage(newBSN)
						oldRootSrcPackage.moveTo(newRootSrcPackage)
					}
				}
				
				val files = newRoot.findFiles
				files.forEach[
					val content = com::google::common::io::Files::toString(it, Charsets::UTF_8).replaceAll(oldNamePrefix, newNamePrefix)
					com::google::common::io::Files::write(content, it, Charsets::UTF_8)
				]
			}
		} else {
			System.err.println("ERROR: pf.group.depth ("+ pf.group.depth +") not not match configured BSNExpectedDepth ("+ config.BSNExpectedDepth +")")
		}
	}
	
	def createRootSrcPackage(File file, String name) {
		new File(file, "src/"+CharMatcher::is('.').replaceFrom(name, "/"))
	}
	
	def moveTo(File from, File to) {
		val toPath = Paths::get(to.toURI);
		if(to.exists) {
			Files::walkFileTree(toPath, new DeleteFileVisitor)
		} else {
			com::google::common::io::Files::createParentDirs(to)
		}
		Files::move(Paths::get(from.toURI), toPath, StandardCopyOption::REPLACE_EXISTING)
	}
	
	def List<File> findFiles(File folder) {
		val list = new ArrayList<File>()
		
		//Find the setting file:
		list.addAll (folder.listFiles[File f| return f.checkIsFile])
		
		//Look in child folders:
		folder
			.listFiles[File f| return f.isDirectory]
			.forEach[list.addAll (it.findFiles)]
		
		return list;
	}
	
	def checkIsFile(File f) {
		f.file && (
			f.name.endsWith(".java") ||
			f.name.endsWith("MANIFEST.MF") ||
			f.name.endsWith(".project") ||
			f.name.endsWith(".xml") ||
			f.name.endsWith(".ini") ||
			f.name.endsWith(".product")
		)
	}
	
	new (IConfig projectConfig) {
		super(projectConfig)
	}
}

class DeleteFileVisitor extends SimpleFileVisitor<Path> {
	
	override visitFile(Path file, BasicFileAttributes attrs) throws IOException {
			Files::delete(file);
			return FileVisitResult::CONTINUE;
	}
	
	override postVisitDirectory(Path dir, IOException e) throws IOException {
		if(e == null) {
			Files::delete(dir);
			return FileVisitResult::CONTINUE;
		} else {
			// directory iteration failed
			throw e;
		}
	}
	
}
 