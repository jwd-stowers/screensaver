// $HeadURL: svn+ssh://js163@orchestra/svn/iccb/screensaver/trunk/src/edu/harvard/med/screensaver/ui/libraries/ScreenViewer.java $
// $Id: ScreenViewer.java 449 2006-08-09 22:53:09Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.screens;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.faces.event.ValueChangeEvent;
import javax.faces.model.DataModel;
import javax.faces.model.ListDataModel;
import javax.faces.model.SelectItem;

import org.apache.log4j.Logger;

import edu.harvard.med.screensaver.model.screens.AbaseTestset;
import edu.harvard.med.screensaver.model.screens.AssayReadoutType;
import edu.harvard.med.screensaver.model.screens.AttachedFile;
import edu.harvard.med.screensaver.model.screens.FundingSupport;
import edu.harvard.med.screensaver.model.screens.LetterOfSupport;
import edu.harvard.med.screensaver.model.screens.Publication;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.model.screens.StatusItem;
import edu.harvard.med.screensaver.model.screens.StatusValue;
import edu.harvard.med.screensaver.model.screens.Visit;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;
import edu.harvard.med.screensaver.model.users.ScreensaverUserRole;
import edu.harvard.med.screensaver.ui.AbstractBackingBean;
import edu.harvard.med.screensaver.ui.control.ScreenResultsController;
import edu.harvard.med.screensaver.ui.control.ScreensController;
import edu.harvard.med.screensaver.ui.control.UIControllerMethod;
import edu.harvard.med.screensaver.ui.searchresults.ScreenSearchResults;
import edu.harvard.med.screensaver.ui.util.JSFUtils;
import edu.harvard.med.screensaver.ui.util.UISelectManyBean;
import edu.harvard.med.screensaver.ui.util.UISelectOneBean;
import edu.harvard.med.screensaver.util.StringUtils;

public class ScreenViewer extends AbstractBackingBean
{
  private static final ScreensaverUserRole EDITING_ROLE = ScreensaverUserRole.SCREENS_ADMIN;

  private static Logger log = Logger.getLogger(ScreenViewer.class);
  
  
  // instance data

  private ScreensController _screensController;
  private ScreenResultsController _screenResultsController;
  
  private Screen _screen;
  private ScreenSearchResults _screenSearchResults;

  private UISelectOneBean<ScreeningRoomUser> _leadScreener;
  private UISelectOneBean<ScreeningRoomUser> _labName;
  private UISelectManyBean<ScreeningRoomUser> _collaborators;
  private FundingSupport _newFundingSupport;
  private StatusValue _newStatusValue;
  private AssayReadoutType _newAssayReadoutType = AssayReadoutType.UNSPECIFIED; // the default (as specified in reqs)
  private String _newKeyword = "";


  
  // public property getter & setter methods

  public ScreensController getScreensController()
  {
    return _screensController;
  }
  
  public void setScreensController(ScreensController screensController)
  {
    _screensController = screensController;
  }
  
  public ScreenResultsController getScreenResultsController()
  {
    return _screenResultsController;
  }
  
  public void setScreenResultsController(ScreenResultsController screenResultsController)
  {
    if (_screenResultsController == screenResultsController) {
      return;
    }
    _screenResultsController = screenResultsController;
    _screenResultsController.setScreenViewer(this);
  }
  
  public Screen getScreen() 
  {
    return _screen;
  }

  public void setScreen(Screen screen) 
  {
    _screen = screen;
  }
  
  public void setCandidateLabHeads(List<ScreeningRoomUser> labHeads)
  {
    _labName = new UISelectOneBean<ScreeningRoomUser>(labHeads, _screen.getLabHead()) { 
      protected String getLabel(ScreeningRoomUser t) { return t.getLabName(); } 
    };
    updateLeadScreenerSelectItems();
  }

  public void setCandidateCollaborators(List<ScreeningRoomUser> screeningRoomUsers)
  {
    _collaborators =
      new UISelectManyBean<ScreeningRoomUser>(screeningRoomUsers, _screen.getCollaborators())
      {
        protected String getLabel(ScreeningRoomUser t)
        {
          return t.getFullName();
        }
      };
  }
  
  public ScreenSearchResults getScreenSearchResults()
  {
    return _screenSearchResults;
  }

  public void setScreenSearchResults(ScreenSearchResults searchResults)
  {
    _screenSearchResults = searchResults;
  }

  public AssayReadoutType getNewAssayReadoutType()
  {
    return _newAssayReadoutType;
  }

  public void setNewAssayReadoutType(AssayReadoutType newAssayReadoutTypeController)
  {
    _newAssayReadoutType = newAssayReadoutTypeController;
  }

  public FundingSupport getNewFundingSupport()
  {
    return _newFundingSupport;
  }

  public void setNewFundingSupport(FundingSupport newFundingSupportController)
  {
    _newFundingSupport = newFundingSupportController;
  }

  public StatusValue getNewStatusValue()
  {
    return _newStatusValue;
  }

  public void setNewStatusValue(StatusValue newStatusValueController)
  {
    _newStatusValue = newStatusValueController;
  }

  public String getNewKeyword()
  {
    return _newKeyword;
  }

  public void setNewKeyword(String newKeyword)
  {
    _newKeyword = newKeyword;
  }
  
  public DataModel getCollaboratorsDataModel()
  {
    return new ListDataModel(new ArrayList<ScreeningRoomUser>(_screen.getCollaborators()));
  }

  public DataModel getStatusItemsDataModel()
  {
    return new ListDataModel(new ArrayList<StatusItem>(_screen.getStatusItems()));
  }

  public DataModel getVisitsDataModel()
  {
    return new ListDataModel(new ArrayList<Visit>(_screen.getVisits()));
  }

  public DataModel getPublicationsDataModel()
  {
    return new ListDataModel(new ArrayList<Publication>(_screen.getPublications()));
  }

  public DataModel getLettersOfSupportDataModel()
  {
    return new ListDataModel(new ArrayList<LetterOfSupport>(_screen.getLettersOfSupport()));
  }

  public DataModel getAttachedFilesDataModel()
  {
    return new ListDataModel(new ArrayList<AttachedFile>(_screen.getAttachedFiles()));
  }

  public DataModel getFundingSupportsDataModel()
  {
    return new ListDataModel(new ArrayList<FundingSupport>(_screen.getFundingSupports()));
  }

  public DataModel getAssayReadoutTypesDataModel()
  {
    return new ListDataModel(new ArrayList<AssayReadoutType>(_screen.getAssayReadoutTypes()));
  }

  public DataModel getAbaseTestsetsDataModel()
  {
    return new ListDataModel(new ArrayList<AbaseTestset>(_screen.getAbaseTestsets()));
  }

  public DataModel getKeywordsDataModel()
  {
    return new ListDataModel(new ArrayList<String>(_screen.getKeywords()));
  }

  public List<SelectItem> getScreenTypeSelectItems()
  {
    return JSFUtils.createUISelectItems(ScreenType.values());
  }

  public UISelectOneBean<ScreeningRoomUser> getLabName()
  {
    return _labName;
  }

  /**
   * Get a list of SelectItems for the screen's collaborators. Collaborators are
   * grouped (and indented) by lab, and the (unindented) lab SelectItem maps to
   * the lab head.
   */
  public UISelectManyBean<ScreeningRoomUser> getCollaborators()
  {
    return _collaborators;
  }
  

  public UISelectOneBean getLeadScreener()
  {
    return _leadScreener;
  }

  public List<SelectItem> getNewStatusValueSelectItems()
  {
    Set<StatusValue> candiateStatusValues = new HashSet<StatusValue>(Arrays.asList(StatusValue.values()));
    for (StatusItem statusItem : _screen.getStatusItems()) {
      candiateStatusValues.remove(statusItem.getStatusValue());
    }
    return JSFUtils.createUISelectItems(candiateStatusValues);
  }

  public List<SelectItem> getNewFundingSupportSelectItems()
  {
    Set<FundingSupport> candiateFundingSupports = new HashSet<FundingSupport>(Arrays.asList(FundingSupport.values()));
    candiateFundingSupports.removeAll(_screen.getFundingSupports());
    return JSFUtils.createUISelectItems(candiateFundingSupports);
  }

  public List<SelectItem> getNewAssayReadoutTypeSelectItems()
  {
    Set<AssayReadoutType> candiateAssayReadoutTypes = new HashSet<AssayReadoutType>(Arrays.asList(AssayReadoutType.values()));
    candiateAssayReadoutTypes.removeAll(_screen.getAssayReadoutTypes());
    return JSFUtils.createUISelectItems(candiateAssayReadoutTypes);
  }
  
  
  /* JSF Application methods */

  /**
   * A command to save the user's edits.
   */
  @UIControllerMethod
  public String saveScreen() {
    _screen.setLabHead(_labName.getSelection());
    _screen.setLeadScreener(_leadScreener.getSelection());
    _screen.setCollaboratorsList(_collaborators.getSelections());
    return _screensController.saveScreen(_screen);
  }
  
  @UIControllerMethod
  public String addStatusItem()
  {
    return _screensController.addStatusItem(_screen, _newStatusValue);
  }
  
  @UIControllerMethod
  public String deleteStatusItem()
  {
    return _screensController.deleteStatusItem(_screen, getSelectedEntityOfType(StatusItem.class));
  }
  
  // TODO: save & go to visit viewer
  public String addCherryPickVisitItem()
  {
    return REDISPLAY_PAGE_ACTION_RESULT;
  }
  
  // TODO: save & go to visit viewer
  public String addNonCherryPickVisitItem()
  {
    return REDISPLAY_PAGE_ACTION_RESULT;
  }
  
  public String copyVisit()
  {
    return REDISPLAY_PAGE_ACTION_RESULT;
  }
  
  public String viewVisit()
  {
    //String visitIdToView = (String) getRequestParameterMap().get(VISIT_ID_PARAM_NAME);
    //_visitViewer.setVisitId(visitIdToView);
    // TODO: implement when Visit Viewer is implemented
    return VIEW_VISIT_ACTION_RESULT;  
  }  
  
  public String viewAttachedFile()
  {
    // TODO: implement when Visit Viewer is implemented
    return VIEW_ATTACHED_FILE_ACTION_RESULT;
  }  
  
  @UIControllerMethod
  public String addPublication()
  {
    return _screensController.addPublication(_screen);
  }
  
  @UIControllerMethod
  public String deletePublication()
  {
    return _screensController.deletePublication(
      _screen,
      getSelectedEntityOfType(Publication.class));
  }
  
  @UIControllerMethod
  public String addLetterOfSupport()
  {
    return _screensController.addLetterOfSupport(_screen);
  }
  
  @UIControllerMethod
  public String deleteLetterOfSupport()
  {
    return _screensController.deleteLetterOfSupport(
      _screen,
      getSelectedEntityOfType(LetterOfSupport.class));
  }
  
  @UIControllerMethod
  public String addAttachedFile()
  {
    return _screensController.addAttachedFile(_screen);
  }
  
  @UIControllerMethod
  public String deleteAttachedFile()
  {
    return _screensController.deleteAttachedFile(
      _screen,
      getSelectedEntityOfType(AttachedFile.class));
  }
  
  @UIControllerMethod
  public String addFundingSupport()
  {
    return _screensController.addFundingSupport(_screen, _newFundingSupport);
  }
  
  @UIControllerMethod
  public String deleteFundingSupport()
  {
    return _screensController.deleteFundingSupport(
      _screen,
      getSelectedEntityOfType(FundingSupport.class));
  }
  
  @UIControllerMethod
  public String addAssayReadoutType()
  {
    return _screensController.addAssayReadoutType(_screen, _newAssayReadoutType);
  }
  
  @UIControllerMethod
  public String deleteAssayReadoutType()
  {
    return _screensController.deleteAssayReadoutType(
      _screen,
      getSelectedEntityOfType(AssayReadoutType.class));
  }
  
  @UIControllerMethod
  public String addAbaseTestset()
  {
    return _screensController.addAbaseTestset(_screen);
  }
  
  @UIControllerMethod
  public String deleteAbaseTestset()
  {
    return _screensController.deleteAbaseTestset(
      _screen,
      getSelectedEntityOfType(AbaseTestset.class));
  }
  
  @UIControllerMethod
  public String addKeyword()
  {
    return _screensController.addKeyword(_screen, _newKeyword);
  }
  
  @UIControllerMethod
  public String deleteKeyword()
  {
    return _screensController.deleteKeyword(
      _screen,
      (String) getHttpServletRequest().getAttribute("keyword"));
  }
  
  public String viewCollaborator()
  {
    //String collaboratorIdToView = (String) getRequestParameterMap().get(COLLABORATOR_ID_PARAM_NAME);
    //_screeningRoomUserViewer.setScreensaverUserId(collaboratorIdToView);
    return VIEW_SCREENING_ROOM_USER_ACTION_RESULT;
  }

  public String viewCollaboratorLabHead()
  {
    // TODO: implement
    return REDISPLAY_PAGE_ACTION_RESULT;
  }

  public String viewLabHead()
  {
    // TODO: implement
    return REDISPLAY_PAGE_ACTION_RESULT;
  }

  public String viewLeadScreener()
  {
    // TODO: implement
    return REDISPLAY_PAGE_ACTION_RESULT;
  }

  public String viewScreenResult()
  {
    return _screenResultsController.viewScreenResult(_screen.getScreenResult());
  }
  
  public String viewBillingInformation()
  {
    return VIEW_BILLING_INFORMATION_ACTION_RESULT;
  }

  
  /* JSF Action event listeners */

  public void update(ValueChangeEvent event) {
    // despite the Tomahawk taglib docs, this event listener is called *before*
    // the *end* of the apply request values phase, preventing the
    // _labName.value property from being updated already
    _labName.setValue((String) event.getNewValue());
    updateLeadScreenerSelectItems();
    getFacesContext().renderResponse();
  }
  
  
  // protected methods

  protected ScreensaverUserRole getEditableAdminRole()
  {
    return EDITING_ROLE;
  }


  // private methods
  
  /**
   * Updates the set of lead screeners that can be selected for this screen.
   * Depends upon the lab head.
   * 
   * @motivation to update the list of lead screeners in the UI, in response to
   *             a new lab head selection, but without updating the entity
   *             before the user saves his edits
   */
  private void updateLeadScreenerSelectItems() {
    ScreeningRoomUser labHead = _labName.getSelection();
    ArrayList<ScreeningRoomUser> leadScreenerCandidates = new ArrayList<ScreeningRoomUser>();
    leadScreenerCandidates.add(labHead);
    leadScreenerCandidates.addAll(labHead.getLabMembers());
    _leadScreener = new UISelectOneBean<ScreeningRoomUser>(leadScreenerCandidates, _screen.getLeadScreener()) {
      protected String getLabel(ScreeningRoomUser t) { return t.getFullName(); } 
    };
  }

  @SuppressWarnings("unchecked")
  private <E> E getSelectedEntityOfType(Class<E> entityClass)
  {
    return (E) getHttpServletRequest().getAttribute(StringUtils.uncapitalize(entityClass.getSimpleName()));
  }

}