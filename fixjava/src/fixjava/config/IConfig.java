/*******************************************************************************
 * Copyright (c) 2013 BSI Business Systems Integration AG.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 *     BSI Business Systems Integration AG - initial API and implementation
 ******************************************************************************/
package fixjava.config;

import java.io.File;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import fixjava.files.GroupFolder;
import fixjava.files.ProjectFolder;

/**
 * Configuration (project specific) for the different fixer.
 */
public interface IConfig {

  File getRootFile();

  int getInitialDepth();

  Collection<String> getLinkedResourcesFiles();

  String getLinkedResourcesLinkLocationURI(String fileName, ProjectFolder project);

  int getBSNExpectedDepth();

  String getBSNNewNamePrefix(GroupFolder group);

  /**
   * Location of the source folders relative to the project.
   * Default Eclipse source folder: singelton list ["src/"]
   * Default Maven source folder: ["src/main/java/", "src/main/resources"]
   */
  List<String> getSrcPath();

  String getCopyright();

  File getAboutFile();

  String getParentGroupId();

  String getParentArtifactId();

  String getParentRelativePath();

  String getWebInfTemplateDirectoy();

  Map<String, String> getRenameProjects();
}
