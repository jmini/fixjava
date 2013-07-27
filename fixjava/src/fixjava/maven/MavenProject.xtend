package fixjava.maven

import java.util.Map

class MavenProject {
	@Property String copyright
	@Property MavenParent parent
	@Property String artifactId
	@Property String packaging
	@Property String name
	@Property Map<String,String> properties
	
	def pomBody() ''''''
}

class MavenParent {
	@Property String groupId
	@Property String artifactId
	@Property String version
}

class MavenProductProject extends MavenProject {
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
		
		
		    <!-- Configure the assembly plugin to build the final server war file -->
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