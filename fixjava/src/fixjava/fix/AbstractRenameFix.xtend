package fixjava.fix

import com.google.common.base.CharMatcher
import fixjava.config.IConfig
import java.io.File
import java.io.IOException
import java.nio.file.FileVisitResult
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.SimpleFileVisitor
import java.nio.file.StandardCopyOption
import java.nio.file.attribute.BasicFileAttributes
import java.util.ArrayList
import java.util.List

/**
 * Fix the bundle symbolic name (and if there is a change, for java project the main package)
 */
abstract class AbstractRenameFix extends AbstractFix {
	def moveSrcFolder(java.io.File projectFolder, String oldName, String newName) {
		config.srcPath.forEach[srcPath|
			val oldRootSrcPackage = projectFolder.createRootSrcPackage(oldName, srcPath)
			if(oldRootSrcPackage.exists) {
				val newRootSrcPackage = projectFolder.createRootSrcPackage(newName, srcPath)
				oldRootSrcPackage.moveTo(newRootSrcPackage)
			}
		]
	}
	
	
	def createRootSrcPackage(File file,String name, String srcPath) {
		new File(file, srcPath+CharMatcher::is('.').replaceFrom(name, "/"))
	}
	
	def moveTo(File from, File to) {
		val toPath = Paths::get(to.toURI);
		if(to.exists) {
			Files::walkFileTree(toPath, new DeleteFileVisitor)
		} else {
			com.google.common.io.Files::createParentDirs(to)
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
			f.name.endsWith(".product") ||
			f.name.endsWith(".properties") ||
			f.name.endsWith(".launch") ||
			f.name.endsWith(".nls")
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