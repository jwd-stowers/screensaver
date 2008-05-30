// $HeadURL$
// $Id$
//
// Copyright 2006 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.screens;

import edu.harvard.med.screensaver.db.GenericEntityDAO;
import edu.harvard.med.screensaver.db.ScreenResultsDAO;
import edu.harvard.med.screensaver.model.screenresults.ScreenResult;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.ui.UIControllerMethod;
import edu.harvard.med.screensaver.ui.screenresults.ScreenResultImporter;
import edu.harvard.med.screensaver.ui.screenresults.ScreenResultViewer;
import edu.harvard.med.screensaver.ui.screenresults.heatmaps.HeatMapViewer;
import edu.harvard.med.screensaver.ui.searchresults.ReagentSearchResults;

import org.apache.log4j.Logger;
import org.springframework.transaction.annotation.Transactional;

public class ScreenViewer extends StudyViewer
{
  // static members

  private static Logger log = Logger.getLogger(ScreenViewer.class);


  // instance data members

  private ScreenViewer _thisProxy;
  private GenericEntityDAO _dao;
  private ScreenResultsDAO _screenResultsDao;
  private ScreenDetailViewer _screenDetailViewer;
  private ScreenResultViewer _screenResultViewer;
  private HeatMapViewer _heatMapViewer;
  private ScreenResultImporter _screenResultImporter;

  private Screen _screen;

  
  // constructors

  /**
   * @motivation for CGLIB2
   */
  protected ScreenViewer()
  {
  }

  public ScreenViewer(ScreenViewer screenViewer,
                      GenericEntityDAO dao,
                      ScreenResultsDAO screenResultsDao,
                      ScreenDetailViewer screenDetailViewer,
                      ReagentSearchResults reagentSearchResults,
                      ScreenResultViewer screenResultViewer,
                      HeatMapViewer heatMapViewer,
                      ScreenResultImporter screenResultImporter)
  {
    super(screenViewer, dao, screenDetailViewer, null, reagentSearchResults);
    _thisProxy = screenViewer;
    _dao = dao;
    _screenResultsDao = screenResultsDao;
    _screenDetailViewer = screenDetailViewer;
    _screenResultViewer = screenResultViewer;
    _heatMapViewer = heatMapViewer;
    _screenResultImporter = screenResultImporter;
  }


  // public methods

  public Screen getScreen()
  {
    return _screen;
  }

  public void setScreen(Screen screen)
  {
    setStudy(screen);
    _screen = screen;
    _screenDetailViewer.setScreen(screen);
    _screenResultImporter.setScreen(screen);
    ScreenResult screenResult = screen.getScreenResult();
    _heatMapViewer.setScreenResult(screenResult);
    _screenResultViewer.setScreenResult(screenResult);
    resetView();
  }
  

  /* JSF Application methods */

  @UIControllerMethod
  public String viewScreen()
  {
    Integer entityId = Integer.parseInt(getRequestParameter("entityId").toString());
    if (entityId == null) {
      throw new IllegalArgumentException("missing 'entityId' request parameter");
    }
    Screen screen = _dao.findEntityById(Screen.class, entityId);
    if (screen == null) {
      throw new IllegalArgumentException(Screen.class.getSimpleName() + " " + entityId + " does not exist");
    }
    return _thisProxy.viewScreen(screen);
  }

  @UIControllerMethod
  @Transactional
  public String viewScreen(final Screen screenIn)
  {
    // TODO: implement as aspect
    if (screenIn.isRestricted()) {
      showMessage("restrictedEntity", "Screen " + screenIn.getScreenNumber());
      log.warn("user unauthorized to view " + screenIn);
      return REDISPLAY_PAGE_ACTION_RESULT;
    }

    Screen screen = _dao.reloadEntity(screenIn,
                                      true,
                                      "labHead",
                                      "labHead.labMembers",
                                      "leadScreener",
                                      "billingInformation");
    _dao.needReadOnly(screen, "collaborators.labHead");
    _dao.needReadOnly(screen, "labActivities.performedBy");
    _dao.needReadOnly(screen,
                      "attachedFiles", 
                      "fundingSupports", 
                      "keywords", 
                      "lettersOfSupport", 
                      "publications");
    _dao.needReadOnly(screen, "statusItems");
    _dao.needReadOnly(screen, "cherryPickRequests");
    _dao.needReadOnly(screen, "annotationTypes.annotationValues");
    _dao.needReadOnly(screen.getScreenResult(), "plateNumbers");
    _dao.needReadOnly(screen.getScreenResult(),
                      "resultValueTypes.derivedTypes",
                      "resultValueTypes.typesDerivedFrom");
    setScreen(screen);
    return VIEW_SCREEN;
  }

  // private methods

  private void resetView()
  {
  }
}

