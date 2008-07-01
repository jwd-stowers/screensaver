// $HeadURL: svn+ssh://ant4@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/src/edu/harvard/med/screensaver/ui/screens/ScreenViewer.java $
// $Id: ScreenViewer.java 2304 2008-04-14 13:31:27Z ant4 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.users;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.SortedSet;
import java.util.TreeSet;

import javax.faces.model.DataModel;
import javax.faces.model.ListDataModel;
import javax.faces.model.SelectItem;

import edu.harvard.med.screensaver.db.GenericEntityDAO;
import edu.harvard.med.screensaver.db.UsersDAO;
import edu.harvard.med.screensaver.model.AbstractEntity;
import edu.harvard.med.screensaver.model.users.AdministratorUser;
import edu.harvard.med.screensaver.model.users.LabAffiliation;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUserClassification;
import edu.harvard.med.screensaver.model.users.ScreensaverUser;
import edu.harvard.med.screensaver.model.users.ScreensaverUserRole;
import edu.harvard.med.screensaver.ui.AbstractBackingBean;
import edu.harvard.med.screensaver.ui.UIControllerMethod;
import edu.harvard.med.screensaver.ui.searchresults.ScreenerSearchResults;
import edu.harvard.med.screensaver.ui.searchresults.StaffSearchResults;
import edu.harvard.med.screensaver.ui.searchresults.UserSearchResults;
import edu.harvard.med.screensaver.ui.util.EditableViewer;
import edu.harvard.med.screensaver.ui.util.JSFUtils;
import edu.harvard.med.screensaver.ui.util.UISelectOneBean;
import edu.harvard.med.screensaver.ui.util.UISelectOneEntityBean;
import edu.harvard.med.screensaver.util.NullSafeComparator;

import org.apache.log4j.Logger;
import org.springframework.transaction.annotation.Transactional;

/**
 * User Viewer backing bean.
 *
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class UserViewer extends AbstractBackingBean implements EditableViewer
{
  // static members

  private static Logger log = Logger.getLogger(UserViewer.class);
  private static final ScreensaverUserRole EDITING_ROLE = ScreensaverUserRole.USERS_ADMIN;
  private static final Comparator<ScreensaverUserRole> USER_ROLE_COMPARATOR = new Comparator<ScreensaverUserRole>() {
    public int compare(ScreensaverUserRole r1, ScreensaverUserRole r2)
    {
      return ((Integer) r1.ordinal()).compareTo(r2.ordinal());
    }
  };


  // instance data members

  private UserViewer _thisProxy;
  private GenericEntityDAO _dao;
  private UsersDAO _usersDao;
  private ScreenerSearchResults _screenerSearchResults;
  private StaffSearchResults _staffSearchResults;

  private ScreensaverUser _user;
  private boolean _isEditMode;
  private AbstractBackingBean _returnToViewAfterEdit;
  private DataModel _userRolesDataModel;
  private UISelectOneBean<ScreensaverUserRole> _newUserRole;
  private UISelectOneEntityBean<ScreeningRoomUser> _labName;
  private UISelectOneEntityBean<LabAffiliation> _labAffiliation;


  // constructors

  /**
   * @motivation for CGLIB2
   */
  protected UserViewer()
  {
  }

  public UserViewer(UserViewer _userViewerProxy,
                    GenericEntityDAO dao,
                    UsersDAO usersDao,
                    ScreenerSearchResults screenerSearchResults,
                    StaffSearchResults staffSearchResults)
  {
    _thisProxy = _userViewerProxy;
    _returnToViewAfterEdit = _thisProxy;
    _dao = dao;
    _usersDao = usersDao;
    _screenerSearchResults = screenerSearchResults;
    _staffSearchResults = staffSearchResults;
  }


  // public methods

  public AbstractEntity getEntity()
  {
    return getUser();
  }

  public ScreensaverUser getUser()
  {
    return _user;
  }

  public ScreeningRoomUser getScreeningRoomUser()
  {
    if (_user instanceof ScreeningRoomUser) {
      return (ScreeningRoomUser) _user;
    }
    return null;
  }

  public AdministratorUser getAdministratorUser()
  {
    if (_user instanceof AdministratorUser) {
      return (AdministratorUser) _user;
    }
    return null;
  }

  @Transactional
  public void setUser(ScreensaverUser user)
  {
    if (user.getEntityId() != null) {
      user = _dao.reloadEntity(user,
                               true,
      "screensaverUserRoles");
      if (user instanceof ScreeningRoomUser) {
        _dao.need(user,
                  "labHead.labAffiliation",
                  "labAffiliation",
        "labMembers");
        _dao.need(user, "screensLed");
        _dao.need(user, "screensHeaded");
        _dao.need(user, "screensCollaborated");
        _dao.need(user, "checklistItems");
      }
    }
    _user = user;
    resetView();
  }

  @Override
  public String reload()
  {
    return _thisProxy.viewUser(_user);
  }

  @Override
  protected ScreensaverUserRole getEditableAdminRole()
  {
    return EDITING_ROLE;
  }

  public boolean isEditMode()
  {
    return _isEditMode;
  }

  @UIControllerMethod
  public String edit()
  {
    _isEditMode = true;
    _returnToViewAfterEdit = _thisProxy;
    return VIEW_USER;
  }

  @UIControllerMethod
  public String cancel()
  {
    _isEditMode = false;
    if (_user.getEntityId() == null) {
      return VIEW_MAIN;
    }
    return _thisProxy.viewUser(_user);
  }

  @UIControllerMethod
  @Transactional
  public String save()
  {
    _isEditMode = false;

    ScreeningRoomUser user = getScreeningRoomUser();
    if (user != null) {
      if (user.getEntityId() == null) {
        user.setLabHead(getLabName().getSelection());
        _dao.persistEntity(user);
      }
      else {
        _dao.reattachEntity(user);
        user.setLabHead(getLabName().getSelection());
      }
      
      user.setLabAffiliation(getLabAffiliation().getSelection());
    }
    else {
      _dao.saveOrUpdateEntity(getUser());
    }
    _dao.flush();
    return _thisProxy.viewUser(_user);
  }

  public List<SelectItem> getUserClassificationSelections()
  {
    return JSFUtils.createUISelectItems(Arrays.asList(ScreeningRoomUserClassification.values()),
                                        _user.getEntityId() == null);
  }

  public UISelectOneEntityBean<ScreeningRoomUser> getLabName()
  {
    if (_labName == null) {
      SortedSet<ScreeningRoomUser> labHeads = _usersDao.findAllLabHeads();
      labHeads.add(null);
      _labName = new UISelectOneEntityBean<ScreeningRoomUser>(labHeads, getScreeningRoomUser().getLabHead(), _dao) {
        protected String getLabel(ScreeningRoomUser t) { return t == null ? "<Lab Head>" : t.getLabName(); }
      };
    }
    return _labName;
  }

  public UISelectOneEntityBean<LabAffiliation> getLabAffiliation()
  {
    if (_labAffiliation == null) {
      SortedSet<LabAffiliation> labAffiliations = new TreeSet<LabAffiliation>(new NullSafeComparator<LabAffiliation>() {
        @Override
        protected int doCompare(LabAffiliation o1, LabAffiliation o2)
        {
          return o1.getAffiliationName().compareTo(o2.getAffiliationName());
        }
      });
      labAffiliations.addAll(_dao.findAllEntitiesOfType(LabAffiliation.class));
      labAffiliations.add(null);
      _labAffiliation = new UISelectOneEntityBean<LabAffiliation>(labAffiliations, getScreeningRoomUser().getLabAffiliation(), _dao) {
        protected String getLabel(LabAffiliation t) { return t == null ? "<none>" : (t.getAffiliationName() + " (" + t.getAffiliationCategory() + ")"); }
      };
    }
    return _labAffiliation;
  }

  public DataModel getUserRolesDataModel()
  {
    if (_userRolesDataModel == null) {
      List<ScreensaverUserRole> userRoles = new ArrayList<ScreensaverUserRole>();
      userRoles.addAll(_user.getScreensaverUserRoles());
      Collections.sort(userRoles, USER_ROLE_COMPARATOR);
      _userRolesDataModel = new ListDataModel(userRoles);
    }
    return _userRolesDataModel;
  }

  public UISelectOneBean<ScreensaverUserRole> getNewUserRole()
  {
    if (_newUserRole == null) {
      Collection<ScreensaverUserRole> candidateNewUserRoles = new TreeSet<ScreensaverUserRole>();
      for (ScreensaverUserRole userRole : ScreensaverUserRole.values()) {
        if (!userRole.isAdministrative() && !_user.getScreensaverUserRoles().contains(userRole)) {
          candidateNewUserRoles.add(userRole);
        }
      }
      _newUserRole = new UISelectOneBean<ScreensaverUserRole>(candidateNewUserRoles) {
        @Override
        protected String getLabel(ScreensaverUserRole r) { return r.getDisplayableRoleName(); }
      };
    }
    return _newUserRole;
  }


  /* JSF Application methods */

  @UIControllerMethod
  @Transactional
  public String viewUser()
  {
    Integer entityId = Integer.parseInt(getRequestParameter("entityId").toString());
    if (entityId == null) {
      throw new IllegalArgumentException("missing 'entityId' request parameter");
    }
    ScreensaverUser user = _dao.findEntityById(ScreensaverUser.class, entityId);
    if (user == null) {
      throw new IllegalArgumentException(ScreensaverUser.class.getSimpleName() + " " + entityId + " does not exist");
    }
    return _thisProxy.viewUser(user);
  }

  @UIControllerMethod
  @Transactional
  public String viewUser(ScreensaverUser user)
  {
    // TODO: implement as aspect
    if (user.isRestricted()) {
      showMessage("restrictedEntity", "user " + user.getFullNameFirstLast());
      log.warn("user unauthorized to view " + user);
      return REDISPLAY_PAGE_ACTION_RESULT;
    }

    setUser(user);

    UserSearchResults searchResults =
      user instanceof ScreeningRoomUser ? _screenerSearchResults : _staffSearchResults;
    // calling viewUser() is a request to view the most up-to-date, persistent
    // version of the user, which means the usersBrowser must also be
    // updated to reflect the persistent version of the user
    searchResults.refetch();

    // all users are viewed within the context of a search results, providing
    // the user with user search options at all times
    // UserSearchResults will call our setUser() method
    if (!searchResults.viewEntity(user)) {
      searchResults.searchUsers();
      // note: calling viewEntity(user) will only work as long as
      // UserSearchResults continues to use InMemoryDataTableModel
      searchResults.viewEntity(user);
    }
    return BROWSE_SCREENERS;

  }

  @UIControllerMethod
  public String editNewUser(ScreensaverUser newUser)
  {
    ScreensaverUser currentUser = getScreensaverUser();
    if (!(currentUser instanceof AdministratorUser &&
      ((AdministratorUser) currentUser).isUserInRole(ScreensaverUserRole.USERS_ADMIN))) {
      showMessage("restrictedOperation", "add a new user");
      return REDISPLAY_PAGE_ACTION_RESULT;
    }

    setUser(newUser);
    _isEditMode = true;
    return VIEW_USER;
  }

  @UIControllerMethod
  public String addUserRole()
  {
    getUser().addScreensaverUserRole(getNewUserRole().getSelection());
    _newUserRole = null;
    _userRolesDataModel = null;
    return REDISPLAY_PAGE_ACTION_RESULT;
  }

  @UIControllerMethod
  public String deleteUserRole()
  {
    getUser().removeScreensaverUserRole((ScreensaverUserRole) getRequestMap().get("element"));
    _newUserRole = null;
    _userRolesDataModel = null;
    return REDISPLAY_PAGE_ACTION_RESULT;
  }


  // private methods

  private void resetView()
  {
    _isEditMode = false;
    _returnToViewAfterEdit = _thisProxy;
    _userRolesDataModel = null;
    _newUserRole = null;
    _labName = null;
    _labAffiliation = null;
  }
}

