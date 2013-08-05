package fixjava.fix

import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import java.io.File
import com.google.common.io.Files
import com.google.common.base.Charsets

class FixVersion extends AbstractFix {
	
	override executeFix(ProjectFolder pf) {
		val pomFile = new File(pf.root, "pom.xml")
		if(pomFile.exists) {
			val pomFileCnt = Files::toString(pomFile, Charsets::UTF_8)
			val newPomFileCnt = pomFileCnt.replaceAll("<version>[A-Z0-9\\.\\-]+</version>", "<version>3.9.0-SNAPSHOT</version>")
			Files::write(newPomFileCnt, pomFile, Charsets::UTF_8)
		}
		val manifestFile = new File(new File(pf.root, "META-INF"), "MANIFEST.MF")
		if(manifestFile.exists) {
			val manifestFileCnt = Files::toString(manifestFile, Charsets::UTF_8)
			val newManifestFileFileCnt = manifestFileCnt.replaceAll("Bundle-Version: [a-z0-9\\.\\-]+", "Bundle-Version: 3.9.0.qualifier")
			Files::write(newManifestFileFileCnt, manifestFile, Charsets::UTF_8)
		}
	}
	
	
	new(IConfig projectConfig) {
		super(projectConfig)
	}
}