// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.settings/org.eclipse.jdt.ui.prefs $
// $Id: org.eclipse.jdt.ui.prefs 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.db.screendb;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import org.apache.log4j.Logger;

import edu.harvard.med.screensaver.model.AbstractEntity;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.libraries.LibraryType;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;
import edu.harvard.med.screensaver.model.users.UserClassification;


/**
 * A proxy to the ScreenDB database. Retrieves data from ScreenDB,
 * encapsulating it into {@link AbstractEntity} objects.
 * 
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 */
public class ScreenDBProxy
{
  
  // static stuff
  
  private static Logger log = Logger.getLogger(ScreenDBProxy.class);

  static {
    try {
      Class.forName("org.postgresql.Driver");
    }
    catch (ClassNotFoundException e) {
      log.error("couldn't find postgresql driver");
    }    
  }

  
  // instance fields
  
  private Connection _connection;
  private Map<Integer,Library> _libraryMap;
  private Map<Integer,ScreeningRoomUser> _screeningRoomUserMap;
  private Map<Integer,Screen> _screenMap;
  
  
  // public constructor and instance methods
  
  /**
   * Construct a <code>ScreenDBProxy</code> object.
   */
  public ScreenDBProxy()
  {
    try {
      _connection = DriverManager.getConnection(
        "jdbc:postgresql://localhost/screendb",
        "screendbweb",
        "screendbweb");
    }
    catch (SQLException e) {
      log.error("couldnt connection to database: " + e.getMessage());
      e.printStackTrace();
    }
  }
  
  /**
   * Get all the libraries from ScreenDB as a collection of {@link
   * Library} entities.
   * @return a collection of the libraries in ScreenDB
   */
  public Collection<Library> getLibraries()
  {
    loadLibraries();
    return _libraryMap.values();
  }
  
  /**
   * Get all the screening room users from ScreenDB as a collection of
   * {@link ScreeningRoomUser} entities. Currently, the eCommons IDs and
   * the lab affiliations are not set.
   * @return a collection of the screening room users in ScreenDB
   */
  public Collection<ScreeningRoomUser> getScreeningRoomUsers()
  {
    loadScreeningRoomUsers();
    return _screeningRoomUserMap.values();
  }
  
  /**
   * Get all the screens from ScreenDB as a collection of {@link Screen}
   * entity objects. Currently, the <code>Screen</code> objects will
   * have no one-to-many relationships or properties defined.
   * @return a collection of the screens in ScreenDB
   */
  public Collection<Screen> getScreens()
  {
    loadScreeningRoomUsers();
    loadScreens();
    return _screenMap.values();
  }
  
  
  // private instance methods
  
  /**
   * Load the libraries from ScreenDB into the {@link #_libraryMap}.
   */
  private void loadLibraries()
  {
    if (_libraryMap != null) {
      return;
    }
    _libraryMap = new HashMap<Integer,Library>();
    LibraryType.UserType libraryTypeUserType = new LibraryType.UserType();
    try {
      Statement statement = _connection.createStatement();
      ResultSet resultSet = statement.executeQuery(
        "SELECT l.*, lt.name AS library_type\n" +
        "FROM library l, library_type lt\n" +
        "WHERE l.library_type_id = lt.id");
      while (resultSet.next()) {
        String libraryName = resultSet.getString("name");
        String shortName = resultSet.getString("short_name");
        LibraryType libraryType = libraryTypeUserType.getTermForValue(
          resultSet.getString("library_type"));
        Integer startPlate = resultSet.getInt("start_plate");
        Integer endPlate = resultSet.getInt("end_plate");
        Library library = new Library(
          libraryName,
          shortName,
          libraryType,
          startPlate,
          endPlate);
        library.setDescription(resultSet.getString("description"));
        Integer id = resultSet.getInt("id");
        _libraryMap.put(id, library);
      }
    }
    catch (SQLException e) {
      log.error("sql error: " + e.getMessage());
      e.printStackTrace();
    }
  }
 
  /**
   * Load the screening room users from ScreenDB into the
   * {@link #_screeningRoomUserMap}.
   */
  private void loadScreeningRoomUsers()
  {
    if (_screeningRoomUserMap != null) {
      return;
    }
    _screeningRoomUserMap = new HashMap<Integer,ScreeningRoomUser>();
    Map<Integer,Integer> memberToHead = new HashMap<Integer,Integer>();
    UserClassification.UserType userClassificationUserType = new UserClassification.UserType();
    try {
      Statement statement = _connection.createStatement();
      ResultSet resultSet = statement.executeQuery(
        "SELECT * FROM users");
      while (resultSet.next()) {
        String email = resultSet.getString("email");
        if (email == null) { // HACK: 3 users currently have no email
          email =
            resultSet.getString("first") + "." +
            resultSet.getString("last") + "@email.is.a.required.field.com";
        }
        UserClassification classification = 
          userClassificationUserType.getTermForValue(resultSet.getString("classification"));
        if (classification == null) {
          classification = UserClassification.UNASSIGNED;
        }
        ScreeningRoomUser user = new ScreeningRoomUser(
          resultSet.getDate("date_created"),
          resultSet.getString("first"),
          resultSet.getString("last"),
          email,
          null, // TODO: put in the eCommonsId when it is in ScreenDB
          resultSet.getString("harvard_id"),
          resultSet.getString("phone"),
          classification,
          resultSet.getBoolean("non_user"),
          resultSet.getBoolean("rani_user"),
          resultSet.getString("lab_location"),
          resultSet.getString("comments"));
        // TODO: include the lab affiliation
        Integer id = resultSet.getInt("id");
        Integer head = resultSet.getInt("lab_name");
        memberToHead.put(id, head);
        _screeningRoomUserMap.put(id, user);
      }
    }
    catch (SQLException e) {
      log.error("sql error: " + e.getMessage());
      e.printStackTrace();
    }
    for (Integer memberId : memberToHead.keySet()) {
      Integer headId = memberToHead.get(memberId);
      ScreeningRoomUser member = _screeningRoomUserMap.get(memberId);
      ScreeningRoomUser head = _screeningRoomUserMap.get(headId);
      if (head != null) {
        member.setLabHead(head);
      }
    }
  }
  
  /**
   * Load the screens from ScreenDB into the {@link #_screenMap}. {@link
   * #loadScreeningRoomUsers} must be called before this method.
   */
  private void loadScreens()
  {
    if (_screenMap != null) {
      return;
    }
    _screenMap = new HashMap<Integer,Screen>();
    ScreenType.UserType screenUserType = new ScreenType.UserType();
    try {
      Statement statement = _connection.createStatement();
      ResultSet resultSet = statement.executeQuery(
        "SELECT * FROM screens");
      while (resultSet.next()) {
        ScreeningRoomUser leadScreener =
          _screeningRoomUserMap.get(resultSet.getInt("user_id"));
        ScreeningRoomUser labHead = leadScreener.getLabHead();
        if (labHead == null) {
          labHead = leadScreener;
        }
        Screen screen = new Screen(
          leadScreener,
          labHead,
          resultSet.getInt("id"),
          resultSet.getDate("date_created"),
          screenUserType.getTermForValue(resultSet.getString("screen_type")),
          resultSet.getString("screen_title"),
          resultSet.getDate("data_mtg_schld"),
          resultSet.getDate("data_mtg_done"),
          resultSet.getString("summary"),
          resultSet.getString("comments"),
          resultSet.getString("study_id"),
          resultSet.getString("protocol_id"));
        Integer id = resultSet.getInt("id");
        _screenMap.put(id, screen);
        // TODO: get all the one-to-many fields
      }
    }
    catch (SQLException e) {
      log.error("sql error: " + e.getMessage());
      e.printStackTrace();
    }
  }
}
