// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.model.screens;

import java.util.Set;
import java.util.SortedSet;

import javax.persistence.Transient;

import edu.harvard.med.screensaver.model.AbstractEntityVisitor;
import edu.harvard.med.screensaver.model.AuditedAbstractEntity;
import edu.harvard.med.screensaver.model.libraries.Reagent;
import edu.harvard.med.screensaver.model.screenresults.AnnotationType;
import edu.harvard.med.screensaver.model.users.AdministratorUser;
import edu.harvard.med.screensaver.model.users.LabHead;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;

public abstract class Study extends AuditedAbstractEntity<Integer>
{
  private static final long serialVersionUID = 1L;
  
  public static final Integer MIN_STUDY_NUMBER = 100000;
  
  protected Study() {}
  
  public Study(AdministratorUser createdBy)
  {
    super(createdBy);
  }

  abstract public SortedSet<ScreeningRoomUser> getCollaborators();

  abstract public LabHead getLabHead();

  abstract public ScreeningRoomUser getLeadScreener();

  abstract public Integer getStudyNumber();

  abstract public StudyType getStudyType();

  abstract public String getTitle();

  abstract public String getSummary();

  abstract public SortedSet<AnnotationType> getAnnotationTypes();

  abstract public Set<Reagent> getReagents();

  abstract public ScreenType getScreenType();

  @Transient
  public boolean isStudyOnly()
  {
    // TODO: this is a total hack; proper solution is waiting on having the Study->Screen->IccbScreen hierarchy in place
    return getStudyNumber() == null || getStudyNumber() >= MIN_STUDY_NUMBER;
  }

  @Override
  public Object acceptVisitor(AbstractEntityVisitor visitor)
  {
    return visitor.visit(this);
  }
}

