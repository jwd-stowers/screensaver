// $HeadURL:
// svn+ssh://ant4@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/src/test/edu/harvard/med/screensaver/TestHibernate.java
// $
// $Id$
//
// Copyright © 2006, 2010 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.db;

import java.io.File;
import java.util.Date;
import java.util.List;

import edu.harvard.med.screensaver.AbstractSpringPersistenceTest;
import edu.harvard.med.screensaver.io.ParseError;
import edu.harvard.med.screensaver.io.ParseErrorsException;
import edu.harvard.med.screensaver.io.workbook2.Workbook;
import edu.harvard.med.screensaver.model.MakeDummyEntities;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.libraries.LibraryType;
import edu.harvard.med.screensaver.model.libraries.LibraryWellType;
import edu.harvard.med.screensaver.model.libraries.WellKey;
import edu.harvard.med.screensaver.model.screenresults.AssayWell;
import edu.harvard.med.screensaver.model.screenresults.ResultValue;
import edu.harvard.med.screensaver.model.screenresults.DataColumn;
import edu.harvard.med.screensaver.model.screenresults.ScreenResult;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.service.libraries.LibraryCreator;
import edu.harvard.med.screensaver.service.screenresult.ScreenResultLoader;
import edu.harvard.med.screensaver.service.screenresult.ScreenResultLoader.MODE;

import org.apache.log4j.Logger;
import org.hibernate.Query;
import org.hibernate.Session;


public class ScreenResultLoaderTest extends AbstractSpringPersistenceTest
{
  private static final Logger log = Logger.getLogger(ScreenResultLoaderTest.class);

  protected ScreenResultLoader screenResultLoader;
  protected LibraryCreator libraryCreator;

  public static final File TEST_INPUT_FILE_DIR = new File("test/edu/harvard/med/screensaver/io/screenresults");
  public static final String SCREEN_RESULT_115_TEST_WORKBOOK_FILE = "ScreenResultTest115.xls";
  public static final int TEST_SCREEN_NUMBER = 115;
  
  @Override
  protected void onSetUp() throws Exception
  {
    super.onSetUp();
    
    final Screen screen = MakeDummyEntities.makeDummyScreen(TEST_SCREEN_NUMBER);
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction()
      {
        genericEntityDao.persistEntity(screen);
        Library library = new Library("library for screen 115 test",
                                      "lwr",
                                      ScreenType.SMALL_MOLECULE,
                                      LibraryType.COMMERCIAL,
                                      1,
                                      3);
        for (int iPlate = 1; iPlate <= 3; ++iPlate) {
          int plateNumber = iPlate;
          for (int col = 'A'; col < 'Q'; col++) {
            for (int row = 1; row <= 24; row++) {
              LibraryWellType libraryWellType = LibraryWellType.EXPERIMENTAL;
              if (plateNumber == 1 && col == 'A') {
                if (row == 1)
                  libraryWellType = LibraryWellType.EMPTY;
                else if (row == 4)
                  libraryWellType = LibraryWellType.EMPTY;
                else if (row == 5)
                  libraryWellType = LibraryWellType.LIBRARY_CONTROL;
                else if (row == 6)
                  libraryWellType = LibraryWellType.BUFFER;
                else if (row == 7)
                  libraryWellType = LibraryWellType.EMPTY;
                else if (row == 8)
                  libraryWellType = LibraryWellType.EMPTY;
              }
              library.createWell(new WellKey(plateNumber, "" + (char) col + row), libraryWellType);
            }
          }
        }
        libraryCreator.createLibrary(library);
      }
    });
    
  }
  
  public void testScreenResultLoaderNoIncrementalFlush() throws Exception
  {
    doTest(false);
  }
  
  public void testScreenResultLoaderIncrementalFlush() throws Exception
  {
    doTest(true);
  }  

  private void doTest(boolean incrementalFlush) throws Exception
  {
    ScreenResult screenResult = null;
    Date now = new Date();
    try {
      File workbookFile = new File(TEST_INPUT_FILE_DIR,
                                   SCREEN_RESULT_115_TEST_WORKBOOK_FILE);
      screenResult = screenResultLoader.parseAndLoad(new Workbook(workbookFile),
                                                     null,
                                                     MODE.DELETE_IF_EXISTS,
                                                     TEST_SCREEN_NUMBER,
                                                     incrementalFlush);
    }
    catch (ParseErrorsException e) {
      log.error("Parse Errors");
      for (ParseError pe : e.getErrors()) {
        log.error("" + pe);
      }
      fail("due to parse errors");
    }
    
    assertTrue("Screen parse time is incorrect: " +
               screenResult.getDateLastImported() + ", should be after: " + now, 
               screenResult.getDateLastImported().getMillis() > now.getTime());

    List<DataColumn> loadedDataColumns = genericEntityDao.findEntitiesByProperty(DataColumn.class,
                                                                               "screenResult",
                                                                               screenResult,
                                                                               true,
                                                                               "resultValues");
    assertNotNull(loadedDataColumns);
    assertEquals("Number of DataColumn's: ", 7, loadedDataColumns.size());
    for (DataColumn actualCol : loadedDataColumns) {
      assertEquals(960, actualCol.getResultValues().size());
    }
    List<AssayWell> assayWells = genericEntityDao.findEntitiesByProperty(AssayWell.class,
                                                                         "screenResult",
                                                                         screenResult);
    assertNotNull(assayWells);
    assertEquals("Number of AssayWells: ", 960, assayWells.size());
    genericEntityDao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction() {
        Screen screen = genericEntityDao.findEntityByProperty(Screen.class, "screenNumber", 115);
        ScreenResult screenResult = screen.getScreenResult();
        assertNotNull(screenResult);
        DataColumn col0 = screenResult.getDataColumnsList().get(0);
        col0.getWellKeyToResultValueMap().keySet().iterator();
        ResultValue rv = col0.getWellKeyToResultValueMap().get(new WellKey(1,"A01"));
        assertEquals(1071894.0, rv.getNumericValue().doubleValue(), 0.01);
        // this tests how Hibernate will make use of WellKey, initializing with a concatenated key string
        rv = col0.getWellKeyToResultValueMap().get(new WellKey("00001:A01"));
        assertEquals(1071894.0, rv.getNumericValue().doubleValue(), 0.01);
      }
    });
    
    genericEntityDao.doInTransaction(new DAOTransaction() {
      public void runTransaction()
      {
        genericEntityDao.runQuery(new edu.harvard.med.screensaver.db.Query() 
        {
          public List execute(Session session)
          {
            String sql =  "select count(*) from screen_result_well_link " +
            		"join screen_result using(screen_result_id) join screen using (screen_id) where screen_number = :screenNumber";
            log.info("sql: " + sql);
            
            Query query = session.createSQLQuery(sql);
            query.setParameter("screenNumber",  TEST_SCREEN_NUMBER);
            Object obj = query.uniqueResult();
            log.info("screen_result_well_link: " + obj);
            
            assertEquals(960,((Number)obj).intValue());
            
            return null;
          }
        });
      }
    });
  }  
}
