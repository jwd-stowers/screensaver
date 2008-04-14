// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/branches/schema-upgrade-2007/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui;

import javax.servlet.http.HttpSession;

import junit.framework.Test;
import junit.framework.TestSuite;

import edu.harvard.med.screensaver.db.DAOTransaction;
import edu.harvard.med.screensaver.io.DataExporter;
import edu.harvard.med.screensaver.model.MakeDummyEntities;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.ui.searchresults.GenericDataExporter;
import edu.harvard.med.screensaver.ui.table.model.DataTableModel;

import org.apache.log4j.Logger;
import org.jboss.jsfunit.facade.JSFClientSession;
import org.jboss.jsfunit.facade.JSFServerSession;

import com.meterware.httpunit.SubmitButton;
import com.meterware.httpunit.WebForm;

/**
 * Top-level class for user interface unit tests. (As this grows, it will be
 * refactored into a reasonable hierarchy of classes.)
 * 
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class ScreensaverJsfUnitTest extends AbstractJsfUnitTest
{
  
  private static final Logger log = Logger.getLogger(ScreensaverJsfUnitTest.class);

  public static Test suite()
  {
    return new TestSuite(ScreensaverJsfUnitTest.class);
  }

//  public void testLogin() throws IOException, SAXException
//  {
//    JSFClientSession client = new JSFClientSession(_webConv, "/main/main.jsf");
//    JSFServerSession server = new JSFServerSession(client);
//
//    if (server.getCurrentViewID().equals("/main/login.xhtml")) {
//      log.info("logging in");
//      WebForm loginForm = client.getWebResponse().getFormWithID("loginForm");
//      assertNotNull("login form exists", loginForm);
//      loginForm.setParameter("j_username", _testUser.getLoginId());
//      loginForm.setParameter("j_password", TEST_USER_PASSWORD);
//      client.submit("loginForm:loginCommand");
////      Button loginButton = loginForm.getButtonWithID("loginForm:loginCommand");
////      assertNotNull("login command button exists", loginButton);
////      loginForm.submit(loginButton);
//      log.info("submitted login request");
//    };
//    server = new JSFServerSession(client);
//  }
  
//public void testLogout() throws Exception
//{
//  JSFClientSession client = new JSFClientSession(_webConv, "/main/main.jsf");
//  JSFServerSession server = new JSFServerSession(client);
//  assertEquals("/main/main.xhtml", server.getCurrentViewID());
//  client.clickCommandLink("userForm:logout");
//  assertEquals("/main/goodbye.xhtml", server.getCurrentViewID());
//  assertFalse("user is not logged in",
//              ((Boolean) server.getManagedBeanValue("#{appInfo.authenticatedUser}")).booleanValue());
//}


  public void testMainPage() throws Exception
  {
    JSFClientSession client = new JSFClientSession(_webConv, "/main/main.jsf");
    JSFServerSession server = new JSFServerSession(client);

    assertEquals("/main/main.xhtml", server.getCurrentViewID());
  
    // test current user is correct
    assertEquals("user is logged in", 
                 TEST_USER_NAME,
                 server.getManagedBeanValue("#{appInfo.screensaverUser.loginId}"));

    // test something on the page
    assertEquals(server.getComponentValue("welcomeMessage"),
                 "Welcome to Screensaver, Test User!");
  }
  
  public void testFindWells() throws Exception
  {
    Library library = MakeDummyEntities.makeDummyLibrary(1, ScreenType.SMALL_MOLECULE, 1);
    _dao.persistEntity(library);
    
    JSFClientSession client = new JSFClientSession(_webConv, "/libraries/wellFinder.jsf");
    JSFServerSession server = new JSFServerSession(client);
    
    WebForm form = client.getWebResponse().getFormWithID("wellFinderForm");
    form.setParameter("plateWellList", "01000 A1 A3");
    SubmitButton findWellsButton = form.getSubmitButton("wellFinderForm:findWellsSubmit");
    form.submit(findWellsButton);
    
    assertEquals("/libraries/wellSearchResults.xhtml", server.getCurrentViewID());
    
    DataTableModel model = (DataTableModel) server.getManagedBeanValue("#{wellsBrowser.dataTableModel}");
    assertEquals("row count", 2, model.getRowCount());
  }
  
  public void testUIControllerMethodExceptionHandlerAspect() throws Exception
  {
    Integer screenNumber = 1;
    final Screen screen = MakeDummyEntities.makeDummyScreen(screenNumber);
    _dao.doInTransaction(new DAOTransaction() {
      public void runTransaction() 
      {
        _dao.persistEntity(screen.getLeadScreener());
        _dao.persistEntity(screen.getLabHead());
        _dao.persistEntity(screen);
      }
    });
    
    JSFClientSession client1 = new JSFClientSession(_webConv, "/main/main.jsf");
    JSFServerSession server1 = new JSFServerSession(client1);
    client1.setParameter("quickFindScreenForm:screenNumber", Integer.toString(screenNumber));
    client1.submit("quickFindScreenSubmit");
    assertEquals("/screens/screenViewer.xhtml", server1.getCurrentViewID());
    assertEquals(screenNumber, (Integer) server1.getManagedBeanValue("#{screenViewer.screen.screenNumber}"));
    log.debug("viewing screen #1 in session " + ((HttpSession) server1.getFacesContext().getExternalContext().getSession(false)).getId());
    
    _dao.doInTransaction(new DAOTransaction() {
      public void runTransaction() 
      {
        Screen screen2 = _dao.reloadEntity(screen);
        screen2.setComments("screen edited!");
      }
    });
    log.debug("edited screen in separate Hibernate session");
    
    client1.submit("screenDetailPanelForm:editCommand");
    log.debug("invoked Edit command on Screen Detail Viewer");
    assertTrue("screen viewer entity is out-of-date", server1.getFacesMessages().hasNext());
    assertTrue("screen viewer entity is out-of-date", server1.getFacesMessages().next().getSummary().startsWith("Other users have already modified the data that you are attempting to update"));
    assertEquals("screen updated to lastest version",
                 "screen edited!",
                 (String) server1.getManagedBeanValue("#{screenViewer.screen.comments}"));
  }
  
  public void testDownloadSearchResults() throws Exception
  {
    final Library library = MakeDummyEntities.makeDummyLibrary(1, ScreenType.SMALL_MOLECULE, 1);
    _dao.persistEntity(library);
    
    JSFClientSession client = new JSFClientSession(_webConv, "/libraries/wellFinder.jsf");
    JSFServerSession server = new JSFServerSession(client);
    client.setParameter("plateWellList", "01000 A1 A2 G12 G13 H20");
    client.submit("wellFinderForm:findWellsSubmit");
    assertEquals("/libraries/wellSearchResults.xhtml", server.getCurrentViewID());
    assertEquals("search result size", new Integer(5), server.getManagedBeanValue("#{wellsBrowser.dataTableModel.rowCount}"));
  
    DataExporter<?> dataExporter = (DataExporter<?>) server.getManagedBeanValue("#{wellsBrowser.dataExporters[0]}");
    assertNotNull("exporter exists", dataExporter);
    assertEquals("exporter type", GenericDataExporter.FORMAT_NAME, dataExporter.getFormatName());
    client.setParameter("downloadFormat",  Integer.toString(dataExporter.hashCode()));
    client.submit("downloadSearchResultsCommandButton");
    assertEquals("download file content type", GenericDataExporter.FORMAT_MIME_TYPE, client.getWebResponse().getContentType());
    assertEquals("download file content type", "Workbook.xls", client.getWebResponse().getTitle());
    //client.getWebResponse().getInputStream();
    
    // TODO: test filtering is respected in export
  }

}