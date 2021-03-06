// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.model.users;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;

import com.google.common.collect.Sets;
import junit.framework.TestSuite;
import org.apache.commons.io.IOUtils;
import org.joda.time.LocalDate;

import edu.harvard.med.screensaver.db.DAOTransaction;
import edu.harvard.med.screensaver.db.DAOTransactionRollbackException;
import edu.harvard.med.screensaver.db.GenericEntityDAO;
import edu.harvard.med.screensaver.db.SchemaUtil;
import edu.harvard.med.screensaver.model.AbstractEntityInstanceTest;
import edu.harvard.med.screensaver.model.AttachedFile;
import edu.harvard.med.screensaver.model.BusinessRuleViolationException;
import edu.harvard.med.screensaver.model.DataModelViolationException;
import edu.harvard.med.screensaver.model.screens.ProjectPhase;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.model.screens.StudyType;
import edu.harvard.med.screensaver.util.CryptoUtils;

public class ScreeningRoomUserTest extends AbstractEntityInstanceTest<ScreeningRoomUser>
{
  public static TestSuite suite()
  {
    return buildTestSuite(ScreeningRoomUserTest.class, ScreeningRoomUser.class);
  }

  public ScreeningRoomUserTest()
  {
    super(ScreeningRoomUser.class);
  }

  public void testUserDigestedPassword()
  {
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction()
      {
        ScreensaverUser user = new ScreeningRoomUser("First", "Last");
        user.setLoginId("myLoginId");
        user.updateScreensaverPassword("myPassword");
        genericEntityDao.saveOrUpdateEntity(user);
      }
    });
    
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction()
      {
        ScreensaverUser user = genericEntityDao.findEntityByProperty(ScreensaverUser.class, "loginId", "myLoginId");
        assertNotNull(user);
        assertEquals(CryptoUtils.digest("myPassword"),
                     user.getDigestedPassword());
      }
    });
  }
  
  public void testLabName()
  {
    initLab();

    ScreeningRoomUser labMember = genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                                                        "lastName",
                                                                        "Member",
                                                                        true,
                                                                        ScreeningRoomUser.LabHead.to(LabHead.labAffiliation));
    assertEquals("lab member with lab head", "Head, Lab - labAffiliation", labMember.getLab().getLabName());
    ScreeningRoomUser labHead = labMember.getLab().getLabHead();
    assertEquals("lab head", "Head, Lab - labAffiliation", labHead.getLab().getLabName());
  }

  public void testRoles() {
    final ScreeningRoomUser user = new ScreeningRoomUser("first",
                                                         "last");

    user.addScreensaverUserRole(ScreensaverUserRole.RNAI_DSL_LEVEL3_SHARED_SCREENS);
    genericEntityDao.saveOrUpdateEntity(user);

    ScreeningRoomUser user2 = genericEntityDao.findEntityById(ScreeningRoomUser.class, user.getEntityId(), false, ScreensaverUser.roles.castToSubtype(ScreeningRoomUser.class));
    assertEquals(Sets.newHashSet(ScreensaverUserRole.RNAI_DSL_LEVEL3_SHARED_SCREENS),
                 user2.getScreensaverUserRoles());

    try {
      ScreeningRoomUser user3 = genericEntityDao.findEntityById(ScreeningRoomUser.class, user.getEntityId(), false, ScreensaverUser.roles.castToSubtype(ScreeningRoomUser.class));
      user3.addScreensaverUserRole(ScreensaverUserRole.READ_EVERYTHING_ADMIN);
      fail("expected DataModelViolationException after adding administrative role to screening room user");
    }
    catch (Exception e) {
      assertTrue(e instanceof DataModelViolationException);
    }
  }

  public void testOnlyLabHeadHasLabAffiliation()
  {
    initLab();
    ScreeningRoomUser labMember =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Member");
    ScreeningRoomUser labHead =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Head");
    List<ScreeningRoomUser> screeningRoomUsers =
      genericEntityDao.findEntitiesByHql(ScreeningRoomUser.class,
                                         "from ScreeningRoomUser sru where sru.labAffiliation is not null");
    assertTrue(screeningRoomUsers.contains(labHead));
    assertFalse(screeningRoomUsers.contains(labMember));
  }

  public void testOnlyLabMembersHaveLabHead()
  {
    initLab();
    List<ScreeningRoomUser> labMembers =
      genericEntityDao.findEntitiesByHql(ScreeningRoomUser.class,
                                         "from ScreeningRoomUser sru where sru.labHead is not null");
    ScreeningRoomUser labHead =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Head");
    ScreeningRoomUser labMember =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Member");
    assertTrue(labMembers.contains(labMember));
    assertFalse(labMembers.contains(labHead));
  }

  public void testSameLabForAllLabMembersAndLabHead()
  {
    initLab();
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction()
      {
        ScreeningRoomUser labMember =
          genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                                "lastName",
                                                "Member");
        ScreeningRoomUser labHead =
          genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                                "lastName",
                                                "Head");
        assertSame(labHead.getLab(), labMember.getLab());
      }
    });
  }

  public void testUserWithoutLab()
  {
    schemaUtil.truncateTables();
    genericEntityDao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction()
      {
        ScreeningRoomUser labMember = new ScreeningRoomUser("Independent", "User");
        genericEntityDao.saveOrUpdateEntity(labMember);
        assertEquals("", labMember.getLab().getLabName());
        assertEquals("", labMember.getLab().getLabAffiliationName());
        assertNull(labMember.getLab().getLabAffiliation());
        assertNull(labMember.getLab().getLabHead());
      }
    });
  }

  public void testLabMemberChangesLab()
  {
    initLab();
    genericEntityDao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction()
      {
        ScreeningRoomUser labMember =
          genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                                "lastName",
                                                "Member");
        assertEquals("Head, Lab - labAffiliation", labMember.getLab().getLabName());

        LabHead labHead2 = new LabHead("Lab", "Head2", new LabAffiliation("LabAffiliation2", AffiliationCategory.HMS));
        genericEntityDao.persistEntity(labHead2);

        labMember.setLab(labHead2.getLab());
      }
    });

    ScreeningRoomUser labMember =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Member",
                                            true,
                                            ScreeningRoomUser.LabHead.to(LabHead.labAffiliation));
    assertEquals("Head2, Lab - LabAffiliation2", labMember.getLab().getLabName());

  }

  public void testLabMemberBecomesLabIndependent()
  {
    initLab();
    genericEntityDao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction()
      {
        ScreeningRoomUser labMember =
          genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                                "lastName",
                                                "Member",
                                                false,
                                                ScreeningRoomUser.LabHead.to(LabHead.labAffiliation));
        assertEquals("Head, Lab - labAffiliation", labMember.getLab().getLabName());
        labMember.setLab(null);
      }
    });

    ScreeningRoomUser labMember =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Member",
                                            true,
                                            ScreeningRoomUser.LabHead.to(LabHead.labAffiliation));
    assertEquals("", labMember.getLab().getLabName());
    assertEquals("", labMember.getLab().getLabAffiliationName());
    assertNull(labMember.getLab().getLabAffiliation());
    assertNull(labMember.getLab().getLabHead());
  }

  public void testLabMemberClassificationCannotBecomePrincipalInvestigator()
  {
    initLab();
    ScreeningRoomUser labMember =
      genericEntityDao.findEntityByProperty(ScreeningRoomUser.class,
                                            "lastName",
                                            "Member",
                                            false,
                                            ScreeningRoomUser.LabHead.to(LabHead.labAffiliation));
    try {
      assertFalse(labMember.isHeadOfLab());
      labMember.setUserClassification(ScreeningRoomUserClassification.GRADUATE_STUDENT); // allowed
      labMember.setUserClassification(ScreeningRoomUserClassification.PRINCIPAL_INVESTIGATOR); // not allowed
      fail("expected BusinessRuleViolationException when attempting to change classification of a lab head");
    }
    catch (BusinessRuleViolationException e) {}
  }
  
  public void testAllAssociatedScreens()
  {
    LabHead labHead = new LabHead("Lab", "Head", new LabAffiliation("labAffiliation", AffiliationCategory.HMS));
    ScreeningRoomUser labMember1 = new ScreeningRoomUser("Lab", "Member1");
    ScreeningRoomUser labMember2 = new ScreeningRoomUser("Lab", "Member2");
    labMember1.setLab(labHead.getLab());
    
    Screen screen1 = new Screen(null, "1", labMember1, labHead, ScreenType.RNAI, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "1");
    Screen screen2 = new Screen(null, "1", labHead, labHead, ScreenType.RNAI, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "2");
    Screen screen3 = new Screen(null, "1", labMember1, null, ScreenType.RNAI, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "3");
    Screen screen4 = new Screen(null, "1", labMember1, null, ScreenType.RNAI, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "4");
    screen4.addCollaborator(labMember2);
    Screen screen5 = new Screen(null, "1", labMember2, labHead, ScreenType.RNAI, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "5");
    screen5.addCollaborator(labMember1);
    
    assertEquals(new HashSet<Screen>(Arrays.asList(screen1, screen2, screen5)), labHead.getAllAssociatedScreens());
    assertEquals(new HashSet<Screen>(Arrays.asList(screen1, screen3, screen4, screen5)), labMember1.getAllAssociatedScreens());
    assertEquals(new HashSet<Screen>(Arrays.asList(screen4, screen5)), labMember2.getAllAssociatedScreens());
  }
  
  public void testChecklistItemEvents()
  {
    schemaUtil.truncateTables();
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction()
      {
        genericEntityDao.persistEntity(new ChecklistItem("trained", false, ChecklistItemGroup.NON_HARVARD_SCREENERS, 1));
        genericEntityDao.persistEntity(new ChecklistItem("lab access", true, ChecklistItemGroup.NON_HARVARD_SCREENERS, 2));
        AdministratorUser admin = new AdministratorUser("Admin", "User");
        ScreeningRoomUser user = new ScreeningRoomUser("Lab", "User");
        genericEntityDao.persistEntity(admin);
        genericEntityDao.persistEntity(user);
      }
    });
    ScreeningRoomUser user = genericEntityDao.findEntityByProperty(ScreeningRoomUser.class, "firstName", "Lab", false, ScreeningRoomUser.checklistItemEvents);
    AdministratorUser admin = genericEntityDao.findEntityByProperty(AdministratorUser.class, "firstName", "Admin", false, ScreensaverUser.activitiesPerformed.castToSubtype(AdministratorUser.class));
    ChecklistItem checklistItem = genericEntityDao.findEntityByProperty(ChecklistItem.class, "itemName", "lab access");
    LocalDate today = new LocalDate();
    ChecklistItemEvent activationEvent = 
      user.createChecklistItemActivationEvent(checklistItem,
                                              today,
                                              admin);
    
    try {
      activationEvent.createChecklistItemExpirationEvent(today.minusDays(1), admin);
      fail("expected DataModelViolationException");
    }
    catch (DataModelViolationException e) {}
    ChecklistItemEvent expirationEvent = 
      activationEvent.createChecklistItemExpirationEvent(today.plusDays(1), admin);
    try {
      expirationEvent.createChecklistItemExpirationEvent(today, admin);
      fail("expected DataModelViolationException");
    }
    catch (DataModelViolationException e) {}
    assertEquals(2, user.getChecklistItemEvents(checklistItem).size());
    assertFalse(user.getChecklistItemEvents(checklistItem).first().isExpiration());
    assertTrue(user.getChecklistItemEvents(checklistItem).last().isExpiration());
    try {
      expirationEvent.createChecklistItemExpirationEvent(today.minusDays(1), admin);
      fail("expected DataModelViolationException");
    }
    catch (DataModelViolationException e) {}
  }

  private void initLab()
  {
    initLab(genericEntityDao, schemaUtil);
  }

  static void initLab(final GenericEntityDAO dao,
                      SchemaUtil schemaUtil)
  {
    schemaUtil.truncateTables();
    dao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction()
      {
        LabHead labHead = new LabHead("Lab", "Head", new LabAffiliation("labAffiliation", AffiliationCategory.HMS));
        ScreeningRoomUser labMember = new ScreeningRoomUser("Lab", "Member");
        labMember.setLab(labHead.getLab());

        dao.saveOrUpdateEntity(labMember);
        dao.saveOrUpdateEntity(labHead);
      }
    });
  }
  
  public void testAddAndDeleteAttachedFiles() throws IOException
  {
    initLab();
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction() {
        ScreeningRoomUser user = genericEntityDao.findEntityByProperty(ScreeningRoomUser.class, "lastName", "Head", false);
        try {
          UserAttachedFileType attachedFileType = new UserAttachedFileType("Screener Correspondence");
          genericEntityDao.persistEntity(attachedFileType);
          user.createAttachedFile("file1.txt", attachedFileType, new LocalDate(), "file1 contents");
        }
        catch (IOException e) {
          throw new DAOTransactionRollbackException(e);
        }
        genericEntityDao.saveOrUpdateEntity(user);
      }
    });
    
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction() {
        ScreeningRoomUser user = (ScreeningRoomUser) genericEntityDao.findEntityByProperty(ScreeningRoomUser.class, "lastName", "Head", true, ScreeningRoomUser.attachedFiles);
        assertEquals("add attached file to user", 1, user.getAttachedFiles().size());
        try {
          assertEquals("attached file contents accessible",
                       "file1 contents",
                       IOUtils.toString(user.getAttachedFiles().iterator().next().getFileContents()));
        }
        catch (Exception e) {
          throw new DAOTransactionRollbackException(e);
        }
      }
    });

    ScreeningRoomUser user = genericEntityDao.findEntityByProperty(ScreeningRoomUser.class, "lastName", "Head", false, ScreeningRoomUser.attachedFiles);
    Iterator<AttachedFile> iter = user.getAttachedFiles().iterator();
    AttachedFile attachedFile = iter.next();
    user.getAttachedFiles().remove(attachedFile);
    genericEntityDao.mergeEntity(user);
    user = genericEntityDao.findEntityByProperty(ScreeningRoomUser.class, "lastName", "Head", true, ScreeningRoomUser.attachedFiles);
    assertEquals("delete attached file from detached user", 0, user.getAttachedFiles().size());
    assertNull(genericEntityDao.reloadEntity(attachedFile));
  }
  
  public void testUpdateFacilityUsageRolesForAssociatedScreens()
  {
    LabHead labHead1 = new LabHead("Lab", "Head1", null);
    LabHead labHead2 = new LabHead("Lab", "Head2", null);
    ScreeningRoomUser screener1 = new ScreeningRoomUser("Lab", "Screener1");
    ScreeningRoomUser screener2 = new ScreeningRoomUser("Lab", "Screener2");

    Screen smScreen = new Screen(null, "1", screener1, labHead1, ScreenType.SMALL_MOLECULE, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "sm");
    doTestUpdateFacilityUsagesRolesForAssociatedScreenss(labHead1,
                                                         labHead2,
                                                         screener1,
                                                         screener2,
                                                         smScreen,
                                                         FacilityUsageRole.SMALL_MOLECULE_SCREENER);
    
    Screen rnaiScreen = new Screen(null, "1", screener1, labHead1, ScreenType.RNAI, StudyType.IN_VITRO, ProjectPhase.PRIMARY_SCREEN, "rnai");
    doTestUpdateFacilityUsagesRolesForAssociatedScreenss(labHead1,
                                                         labHead2,
                                                         screener1,
                                                         screener2,
                                                         rnaiScreen,
                                                         FacilityUsageRole.RNAI_SCREENER);
  }

  private void doTestUpdateFacilityUsagesRolesForAssociatedScreenss(LabHead labHead1,
                                                                    LabHead labHead2,
                                                                    ScreeningRoomUser screener1,
                                                                    ScreeningRoomUser screener2,
                                                                    Screen screen,
                                                                    FacilityUsageRole facilityUsageRole)
  {
    screen.addCollaborator(screener2);
    assertTrue(labHead1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertFalse(labHead2.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener2.getFacilityUsageRoles().contains(facilityUsageRole));
    
    screen.setLabHead(labHead2);
    assertFalse(labHead1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(labHead2.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener2.getFacilityUsageRoles().contains(facilityUsageRole));
    
    screen.removeCollaborator(screener2);
    screen.setLeadScreener(screener2);
    assertFalse(labHead1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(labHead2.getFacilityUsageRoles().contains(facilityUsageRole));
    assertFalse(screener1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener2.getFacilityUsageRoles().contains(facilityUsageRole));

    screen.addCollaborator(screener1);
    assertFalse(labHead1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(labHead2.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener1.getFacilityUsageRoles().contains(facilityUsageRole));
    assertTrue(screener2.getFacilityUsageRoles().contains(facilityUsageRole));
  }
  
  public void testNewUserStartsWithMininalDataAccessPrivileges()
  {
    ScreeningRoomUser user = new ScreeningRoomUser("Test", "Screener");
    genericEntityDao.persistEntity(user);
    assertFalse("new user not a small molecule screener", user.getScreensaverUserRoles().contains(ScreensaverUserRole.SM_DSL_LEVEL3_SHARED_SCREENS));
    assertFalse("new user starts at level 3 (no mutual screens role)", user.getScreensaverUserRoles().contains(ScreensaverUserRole.SM_DSL_LEVEL1_MUTUAL_SCREENS)); 
    assertFalse("new user starts at level 3 (no mutual positives role)", user.getScreensaverUserRoles().contains(ScreensaverUserRole.SM_DSL_LEVEL2_MUTUAL_POSITIVES)); 
    assertFalse("no login privileges", user.getScreensaverUserRoles().contains(ScreensaverUserRole.SCREENSAVER_USER));
  }

}

