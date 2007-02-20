// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.control;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import edu.harvard.med.screensaver.db.DAO;
import edu.harvard.med.screensaver.db.DAOTransaction;
import edu.harvard.med.screensaver.db.DAOTransactionRollbackException;
import edu.harvard.med.screensaver.io.screenresults.ScreenResultExporter;
import edu.harvard.med.screensaver.io.screenresults.ScreenResultParser;
import edu.harvard.med.screensaver.io.workbook.Workbook;
import edu.harvard.med.screensaver.model.DuplicateEntityException;
import edu.harvard.med.screensaver.model.screenresults.ScreenResult;
import edu.harvard.med.screensaver.model.screens.AttachedFile;
import edu.harvard.med.screensaver.model.screens.FundingSupport;
import edu.harvard.med.screensaver.model.screens.LetterOfSupport;
import edu.harvard.med.screensaver.model.screens.Publication;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.StatusItem;
import edu.harvard.med.screensaver.model.screens.StatusValue;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;
import edu.harvard.med.screensaver.ui.screenresults.HeatMapViewer;
import edu.harvard.med.screensaver.ui.screenresults.ScreenResultImporter;
import edu.harvard.med.screensaver.ui.screenresults.ScreenResultViewer;
import edu.harvard.med.screensaver.ui.screens.ScreenFinder;
import edu.harvard.med.screensaver.ui.screens.ScreenViewer;
import edu.harvard.med.screensaver.ui.screens.ScreensBrowser;
import edu.harvard.med.screensaver.ui.searchresults.ScreenSearchResults;
import edu.harvard.med.screensaver.ui.util.JSFUtils;

import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.myfaces.custom.fileupload.UploadedFile;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.springframework.dao.ConcurrencyFailureException;
import org.springframework.dao.DataAccessException;

/**
 * 
 *
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
public class ScreensControllerImpl extends AbstractUIController implements ScreensController
{
  
  // private static final fields
  
  private static final Logger log = Logger.getLogger(ScreensController.class);
  private static final String BROWSE_SCREENS = "browseScreens";
  private static final String VIEW_SCREEN = "viewScreen";
  private static String VIEW_SCREEN_RESULT_IMPORT_ERRORS = "viewScreenResultImportErrors";
  private static String VIEW_SCREEN_RESULT = "viewScreenResult";

  
  // private instance fields
  
  private DAO _dao;
  private LibrariesController _librariesController;
  private ScreensBrowser _screensBrowser;
  private ScreenViewer _screenViewer;
  private ScreenResultViewer _screenResultViewer;
  private ScreenFinder _screenFinder;
  private HeatMapViewer _heatMapViewer;
  private ScreenResultImporter _screenResultImporter;
  private ScreenResultExporter _screenResultExporter;
  private Screen _currentScreen;
 

  // public getters and setters
  
  public DAO getDao()
  {
    return _dao;
  }
  
  public void setDao(DAO dao)
  {
    _dao = dao;
  }
  
  public void setLibrariesController(LibrariesController librariesController)
  {
    _librariesController = librariesController;
  }
  
  public ScreensBrowser getScreensBrowser()
  {
    return _screensBrowser;
  }
  
  public void setScreensBrowser(ScreensBrowser screensBrowser)
  {
    _screensBrowser = screensBrowser;
  }
  
  public void setScreenViewer(ScreenViewer screenViewer)
  {
    _screenViewer = screenViewer;
  }
  
  public void setScreenResultViewer(ScreenResultViewer screenResultViewer)
  {
    _screenResultViewer = screenResultViewer;
  }

  public void setScreenFinder(ScreenFinder screenFinder)
  {
    _screenFinder = screenFinder;
  }

  public void setHeatMapViewer(HeatMapViewer heatMapViewer) 
  {
    _heatMapViewer = heatMapViewer;
  }

  public void setScreenResultImporter(ScreenResultImporter screenResultImporter) 
  {
    _screenResultImporter = screenResultImporter;
  }

  public void setScreenResultExporter(ScreenResultExporter screenResultExporter) 
  {
    _screenResultExporter = screenResultExporter;
  }

 
  // public controller methods

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#browseScreens()
   */
  @UIControllerMethod
  public String browseScreens()
  {
    _dao.doInTransaction(new DAOTransaction() 
    {
      public void runTransaction()
      {
        List<Screen> screens = _dao.findAllEntitiesWithType(Screen.class);
        for (Screen screen : screens) {
          _dao.need(screen, 
                    "screenResult", 
                    // TODO: only need this for screensAdmin or
                    // readEverythingAdmin; query would be faster if not
                    // requested
                    "statusItems"); 
        }
        _screensBrowser.setScreenSearchResults(new ScreenSearchResults(screens,
                                                                       ScreensControllerImpl.this, 
                                                                       _dao));
      }
    });
    return BROWSE_SCREENS;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#browseMyScreens()
   */
  @UIControllerMethod
  public String browseMyScreens()
  {
    final String[] result = { REDISPLAY_PAGE_ACTION_RESULT };
    _dao.doInTransaction(new DAOTransaction() 
    {
      public void runTransaction()
      {
        Set<Screen> screens = new HashSet<Screen>();
        if (getScreensaverUser() instanceof ScreeningRoomUser) {
          ScreeningRoomUser screener = (ScreeningRoomUser) getScreensaverUser();
          screens.addAll(screener.getScreensHeaded());
          screens.addAll(screener.getScreensLed());
          screens.addAll(screener.getScreensCollaborated());
          if (screens.size() == 0) {
            showMessage("screens.noScreensForUser");
          }
          else {
            for (Screen screen : screens) {
              _dao.need(screen, 
                        "screenResult");
            }
            _screensBrowser.setScreenSearchResults(new ScreenSearchResults(new ArrayList<Screen>(screens),
                                                                           ScreensControllerImpl.this, 
                                                                           _dao));
            result[0] = BROWSE_SCREENS;
          }
        }
        else {
          // admin user!
          showMessage("screens.noScreensForUser");
        }
      }
    });
    return result[0];
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#viewScreen(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.ui.searchresults.ScreenSearchResults)
   */
  @UIControllerMethod
  public String viewScreen(final Screen screenIn, ScreenSearchResults screenSearchResults)
  {
    _screenViewer.setDao(_dao);

    _screenResultImporter.setDao(_dao);
    _screenResultImporter.setMessages(getMessages());
    _screenResultImporter.setScreenResultParser(new ScreenResultParser(_dao));

    _screenResultViewer.setDao(_dao);
    _screenResultViewer.setMessages(getMessages());
    _screenResultViewer.setScreenResultExporter(_screenResultExporter);
    _screenResultViewer.setLibrariesController(_librariesController);

    _screensBrowser.setScreenSearchResults(screenSearchResults);

    _heatMapViewer.setDao(_dao);
    _heatMapViewer.setLibrariesController(_librariesController);

    try {
      _dao.doInTransaction(new DAOTransaction() 
      {
        public void runTransaction()
        {
          Screen screen = _currentScreen = (Screen) _dao.reloadEntity(screenIn);
          _dao.need(screen, 
                    "abaseTestsets",
                    "attachedFiles",
                    "billingInformation",
                    "fundingSupports",
                    "keywords",
                    "lettersOfSupport",
                    "publications",
                    "statusItems",
                    "visits",
                    "hbnCollaborators",
                    "hbnLabHead",
                    "hbnLabHead.hbnLabMembers",
                    "hbnLeadScreener",
                    "screenResult.plateNumbers",
                    "screenResult.hbnResultValueTypes",
                    "screenResult.hbnResultValueTypes.hbnDerivedTypes",
                    "screenResult.hbnResultValueTypes.hbnTypesDerivedFrom");
          
          ScreenResult permissionsAwareScreenResult = 
            _dao.findEntityById(ScreenResult.class, 
                                screen.getScreenResult() == null ? -1 : 
                                  screen.getScreenResult().getEntityId());

          _screenViewer.setScreen(screen);
          _screenResultImporter.setScreen(screen);
          _screenResultViewer.setScreen(screen);
          _heatMapViewer.setScreenResult(permissionsAwareScreenResult);
          _screenResultViewer.setScreenResult(permissionsAwareScreenResult);
          if (permissionsAwareScreenResult != null &&
            permissionsAwareScreenResult.getResultValueTypes().size() > 0) {
            _screenResultViewer.setScreenResultSize(permissionsAwareScreenResult.getResultValueTypesList().get(0).getResultValues().size());
          }
        }
      });
    }
    catch (DataAccessException e) {
      showMessage("databaseOperationFailed", e.getMessage());
    }
      
    return VIEW_SCREEN;
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#editScreen(edu.harvard.med.screensaver.model.screens.Screen)
   */
  @UIControllerMethod
  public String editScreen(final Screen screen)
  {
    try {
      _dao.doInTransaction(new DAOTransaction() 
      {
        public void runTransaction()
        {
          _dao.reattachEntity(screen); // checks if up-to-date
          _dao.need(screen, "hbnLabHead.hbnLabMembers");
        }
      });
      return REDISPLAY_PAGE_ACTION_RESULT;
    }
    catch (ConcurrencyFailureException e) {
      showMessage("concurrentModificationConflict");
    }
    catch (DataAccessException e) {
      showMessage("databaseOperationFailed", e.getMessage());
    }
    return viewLastScreen(); // reload
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#saveScreen(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.db.DAOTransaction)
   */
  @UIControllerMethod
  public String saveScreen(final Screen screen, final DAOTransaction updater)
  {
    try {
      _dao.doInTransaction(new DAOTransaction()
      {
        public void runTransaction()
        {
          _dao.reattachEntity(screen);
          if (updater != null) {
            updater.runTransaction();
          }
        }
      });
    }
    catch (ConcurrencyFailureException e) {
      showMessage("concurrentModificationConflict");
      viewLastScreen();
    }
    catch (DataAccessException e) {
      showMessage("databaseOperationFailed", e.getMessage());
      viewLastScreen();
    }
    screenSearchResultsChanged();
    return VIEW_SCREEN;
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deleteScreenResult(edu.harvard.med.screensaver.model.screenresults.ScreenResult)
   */
  @UIControllerMethod
  public String deleteScreenResult(ScreenResult screenResult)
  {
    if (screenResult != null) {
      try {
        _dao.deleteScreenResult(screenResult);
      }
      catch (ConcurrencyFailureException e) {
        showMessage("concurrentModificationConflict");
      }
      catch (DataAccessException e) {
        showMessage("databaseOperationFailed", e.getMessage());
      }
    }
    screenSearchResultsChanged();
    return viewLastScreen();
  }

  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#viewLastScreen()
   */
  @UIControllerMethod
  public String viewLastScreen()
  {
    return viewScreen(_currentScreen, 
                      _screensBrowser.getScreenSearchResults());
  }
    
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#viewScreenResultImportErrors()
   */
  @UIControllerMethod
  public String viewScreenResultImportErrors()
  {
    return VIEW_SCREEN_RESULT_IMPORT_ERRORS;
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#addStatusItem(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.StatusValue)
   */
  @UIControllerMethod
  public String addStatusItem(Screen screen, StatusValue statusValue)
  {
    if (statusValue != null) {
      try {
        new StatusItem(screen,
                       new Date(),
                       statusValue);
      }
      catch (DuplicateEntityException e) {
        showMessage("screens.duplicateEntity", "status item");
      }
      _screenViewer.setNewStatusValue(null);
    }
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deleteStatusItem(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.StatusItem)
   */
  @UIControllerMethod
  public String deleteStatusItem(Screen screen, StatusItem statusItem)
  {
    screen.getStatusItems().remove(statusItem);
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#addPublication(edu.harvard.med.screensaver.model.screens.Screen)
   */
  @UIControllerMethod
  public String addPublication(Screen screen)
  {
    try {
      new Publication(screen, "<new>", "", "", "");
    }
    catch (DuplicateEntityException e) {
      showMessage("screens.duplicateEntity", "publication");
    }
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deletePublication(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.Publication)
   */
  @UIControllerMethod
  public String deletePublication(Screen screen, Publication publication)
  {
    screen.getPublications().remove(publication);
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#addLetterOfSupport(edu.harvard.med.screensaver.model.screens.Screen)
   */
  @UIControllerMethod
  public String addLetterOfSupport(Screen screen)
  {
    try {
      new LetterOfSupport(screen, new Date(), "");
    }
    catch (DuplicateEntityException e) {
      showMessage("screens.duplicateEntity", "letter of support");
    }
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deleteLetterOfSupport(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.LetterOfSupport)
   */
  @UIControllerMethod
  public String deleteLetterOfSupport(Screen screen, LetterOfSupport letterOfSupport)
  {
    screen.getLettersOfSupport().remove(letterOfSupport);
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#addAttachedFile(edu.harvard.med.screensaver.model.screens.Screen)
   */
  @UIControllerMethod
  public String addAttachedFile(Screen screen)
  {
    try {
      new AttachedFile(screen, "<new>", "");
    }
    catch (DuplicateEntityException e) {
      showMessage("screens.duplicateEntity", "attached file");
    }
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deleteAttachedFile(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.AttachedFile)
   */
  @UIControllerMethod
  public String deleteAttachedFile(Screen screen, AttachedFile attachedFile)
  {
    screen.getAttachedFiles().remove(attachedFile);
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#addFundingSupport(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.FundingSupport)
   */
  @UIControllerMethod
  public String addFundingSupport(Screen screen, FundingSupport fundingSupport)
  {
    if (fundingSupport != null) {
      if (!screen.addFundingSupport(fundingSupport)) {
        showMessage("screens.duplicateEntity", "funding support");
      }
      _screenViewer.setNewFundingSupport(null);
    }
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deleteFundingSupport(edu.harvard.med.screensaver.model.screens.Screen, edu.harvard.med.screensaver.model.screens.FundingSupport)
   */
  @UIControllerMethod
  public String deleteFundingSupport(Screen screen, FundingSupport fundingSupport)
  {
    screen.getFundingSupports().remove(fundingSupport);
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#addKeyword(edu.harvard.med.screensaver.model.screens.Screen, java.lang.String)
   */
  @UIControllerMethod
  public String addKeyword(Screen screen, String keyword)
  {
    if (! screen.addKeyword(keyword)) {
      showMessage("screens.duplicateEntity", "keyword");
    }
    else {
      _screenViewer.setNewKeyword("");
    }
    return VIEW_SCREEN;
  }
  
  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#deleteKeyword(edu.harvard.med.screensaver.model.screens.Screen, java.lang.String)
   */
  @UIControllerMethod
  public String deleteKeyword(Screen screen, String keyword)
  {
    screen.getKeywords().remove(keyword);
    return VIEW_SCREEN;
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#findScreen(java.lang.Integer)
   */
  public String findScreen(Integer screenNumber)
  {
    if (screenNumber != null) {
      Screen screen = _dao.findEntityByProperty(Screen.class, "hbnScreenNumber", screenNumber);
      if (screen != null) {
        return viewScreen(screen, null);
      }
      else {
        showMessage("screens.noSuchScreenNumber", screenNumber);
      }
    }
    else {
      showMessage("screens.screenNumberRequired", screenNumber);
    }
    return REDISPLAY_PAGE_ACTION_RESULT;
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#importScreenResult(edu.harvard.med.screensaver.model.screens.Screen, org.apache.myfaces.custom.fileupload.UploadedFile, edu.harvard.med.screensaver.io.screenresults.ScreenResultParser)
   */
  @UIControllerMethod
  public String importScreenResult(final Screen screenIn,
                                   final UploadedFile uploadedFile,
                                   final ScreenResultParser parser)
  {
    try {
      _dao.doInTransaction(new DAOTransaction() 
      {
        public void runTransaction()
        {
          Screen screen = (Screen) _dao.reloadEntity(screenIn);
          log.info("starting import of ScreenResult for Screen " + screen);

          try {
            if (uploadedFile.getInputStream().available() > 0) {
              parser.parse(screen, 
                           new File("screen_result_" + screen.getScreenNumber()),
                           uploadedFile.getInputStream());
              if (parser.getErrors().size() > 0) {
                // these are data-related "user" errors, so we log at "info" level
                log.info("parse errors encountered during import of ScreenResult for Screen " + screenIn);
                throw new ScreenResultParseErrorsException("parse errors encountered");
              }
              else {
                log.info("successfully parsed ScreenResult for Screen " + screenIn);
              }
            }
          }
          catch (IOException e) {
            showMessage("systemError", e.getMessage());
            throw new DAOTransactionRollbackException("could not access uploaded file", e);
          }
        }
      });
    }
    catch (DataAccessException e) {
      showMessage("databaseOperationFailed", e.getMessage());
    }
    catch (ScreenResultParseErrorsException e) {
      return viewScreenResultImportErrors();
    }
    screenSearchResultsChanged();
    return viewLastScreen();
  }

  /* (non-Javadoc)
   * @see edu.harvard.med.screensaver.ui.control.ScreensController#downloadScreenResult(edu.harvard.med.screensaver.model.screenresults.ScreenResult)
   */
  @UIControllerMethod
  public String downloadScreenResult(final ScreenResult screenResultIn)
  {
    try {
      _dao.doInTransaction(new DAOTransaction() 
      {
        public void runTransaction()
        {
          ScreenResult screenResult = (ScreenResult) _dao.reloadEntity(screenResultIn);
          File exportedWorkbookFile = null;
          FileOutputStream out = null;
          try {
            if (screenResult != null) {
              HSSFWorkbook workbook = _screenResultExporter.build(screenResult);
              exportedWorkbookFile = File.createTempFile("screenResult" + screenResult.getScreen().getScreenNumber() + ".", 
              ".xls");
              out = new FileOutputStream(exportedWorkbookFile);
              workbook.write(out);
              out.close();
              JSFUtils.handleUserFileDownloadRequest(getFacesContext(),
                                                     exportedWorkbookFile,
                                                     Workbook.MIME_TYPE);
            }
          }
          catch (IOException e)
          {
            reportApplicationError(e);
          }
          finally {
            IOUtils.closeQuietly(out);
            if (exportedWorkbookFile != null && exportedWorkbookFile.exists()) {
              exportedWorkbookFile.delete();
            }
          }
        }
      });
    }
    catch (DataAccessException e) {
      showMessage("databaseOperationFailed", e.getMessage());
    }
    return REDISPLAY_PAGE_ACTION_RESULT;
  }

  
  // private methods

  /**
   * Poor man's "event" (we don't have a real app event architecture, currently) to
   * be invoked when the ScreenSearchResults may have become stale.
   */
  private void screenSearchResultsChanged()
  {
    // TODO: should attempt to maintain search result position, sort order,
    // etc.; right now, we just clear the search result, causing it be recreated
    // entirely when browseScreens() is called
    _screensBrowser.setScreenSearchResults(null);
  }
}

