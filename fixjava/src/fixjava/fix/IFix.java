package fixjava.fix;

import fixjava.files.GroupFolder;
import fixjava.files.ProjectFolder;

public interface IFix {

  void executeFix(GroupFolder groupFolder);

  void executeFix(ProjectFolder projectFolder);
}
