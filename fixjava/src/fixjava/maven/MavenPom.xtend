package fixjava.maven

import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

@ToString
class MavenPom {
	@Accessors String copyright
	@Accessors MavenParent parent
	@Accessors String groupId
	@Accessors String artifactId
	@Accessors String packaging
	@Accessors String name
	@Accessors Map<String,String> properties
	
	def pomBody() ''''''
}

@ToString
class MavenParent {
	@Accessors String groupId
	@Accessors String artifactId
	@Accessors String version
	@Accessors String relativePath
}

@ToString
class MavenParentPom extends MavenPom {

	@Accessors List<String> modules

	new() {
		packaging = "pom"
	}
	
	override pomBody() '''
		«IF !modules.nullOrEmpty»
		<modules>
		  «FOR m : modules»
		  <module>«m»</module>
		  «ENDFOR»
		</modules>
		«ENDIF»
	'''
}

class MavenProductPom extends MavenPom {
	new() {
		packaging = "eclipse-repository"
	}
	
	override pomBody() '''
		<build>
		  <plugins>
		    <plugin>
		      <groupId>org.eclipse.tycho</groupId>
		      <artifactId>tycho-p2-director-plugin</artifactId>
		      <executions>
		        <execution>
		          <id>materialize-products</id>
		          <phase>package</phase>
		          <goals>
		            <goal>materialize-products</goal>
		          </goals>
		        </execution>
		      </executions>
		      <configuration>
		        <products>
		          <product>
		            <id>${product.id}</id>
		          </product>
		        </products>
		      </configuration>
		    </plugin>
		    
		    <!-- Workaround: Use an existing config.ini file (caused by the problem that tycho will always generate a default one) -->
		    <plugin>
		      <artifactId>maven-resources-plugin</artifactId>
		      <executions>
		        <execution>
		          <phase>package</phase>
		          <goals>
		            <goal>copy-resources</goal>
		          </goals>
		          <configuration>
		            <resources>
		              <resource>
		                <directory>${project.build.directory}/../</directory>
		                <filtering>false</filtering>
		                <includes>
		                  <include>config.ini</include>
		                </includes>
		              </resource>
		            </resources>
		            <outputDirectory>${product.outputDirectory}/configuration</outputDirectory>
		            <overwrite>true</overwrite>
		          </configuration>
		        </execution>
		      </executions>
		    </plugin>
		    
		    
		    <!-- Configure the assembly plugin to build the final file (war or zip) -->
		    <plugin>
		      <artifactId>maven-assembly-plugin</artifactId>
		      <configuration>
		        <descriptors>
		          <descriptor>assembly.xml</descriptor>
		        </descriptors>
		        <finalName>${product.finalName}</finalName>
		        <appendAssemblyId>false</appendAssemblyId>
		      </configuration>
		      <executions>
		        <execution>
		          <id>make-assembly</id>
		          <phase>package</phase>
		          <goals>
		            <goal>single</goal>
		          </goals>
		        </execution>
		      </executions>
		    </plugin>
		  </plugins>
		</build>
	'''
}