// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.
  
package edu.harvard.med.screensaver.service.cherrypicks;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import edu.harvard.med.screensaver.AbstractSpringPersistenceTest;
import edu.harvard.med.screensaver.db.DAOTransaction;
import edu.harvard.med.screensaver.model.libraries.Copy;
import edu.harvard.med.screensaver.model.libraries.CopyInfo;
import edu.harvard.med.screensaver.model.libraries.CopyUsageType;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.libraries.PlateType;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.libraries.WellKey;
import edu.harvard.med.screensaver.model.libraries.WellName;
import edu.harvard.med.screensaver.model.screens.CherryPickAssayPlate;
import edu.harvard.med.screensaver.model.screens.CherryPickRequest;
import edu.harvard.med.screensaver.model.screens.LabCherryPick;
import edu.harvard.med.screensaver.model.screens.ScreenerCherryPick;

import org.apache.log4j.Logger;

public class CherryPickRequestPlateMapperTest extends AbstractSpringPersistenceTest
{
  // static members

  private static Logger log = Logger.getLogger(CherryPickRequestPlateMapperTest.class);

  
  // instance data members
  
  protected CherryPickRequestPlateMapper cherryPickRequestPlateMapper;
  protected CherryPickRequestAllocator cherryPickRequestAllocator;
  

  // public constructors and methods
  
  public void testCherryPickPlateMapper()
  {
    dao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction() {
        Library duplexLibrary = CherryPickRequestAllocatorTest.makeRNAiDuplexLibrary("Duplexes library", 1, 6, 384);
        makeLibraryCopy(duplexLibrary, "C", 10);
        makeLibraryCopy(duplexLibrary, "D", 10);
        dao.persistEntity(duplexLibrary);

        // create and allocate a cherry pick request, to cause next cherry pick request to draw from multiple plates
        {
          CherryPickRequest earlierCherryPickRequest = CherryPickRequestAllocatorTest.createCherryPickRequest(1, 10);
          ScreenerCherryPick dummyScreenerCherryPick = new ScreenerCherryPick(earlierCherryPickRequest, 
                                                                              dao.findWell(new WellKey(1, "A01")));
          new LabCherryPick(dummyScreenerCherryPick, dao.findWell(new WellKey(5, "A01")));
          new LabCherryPick(dummyScreenerCherryPick, dao.findWell(new WellKey(5, "A02")));
          new LabCherryPick(dummyScreenerCherryPick, dao.findWell(new WellKey(5, "A03")));
          new LabCherryPick(dummyScreenerCherryPick, dao.findWell(new WellKey(6, "A01")));
          new LabCherryPick(dummyScreenerCherryPick, dao.findWell(new WellKey(6, "A02")));
          new LabCherryPick(dummyScreenerCherryPick, dao.findWell(new WellKey(6, "A03")));
          dao.persistEntity(earlierCherryPickRequest.getScreen());
          cherryPickRequestAllocator.allocate(earlierCherryPickRequest);
        }

        CherryPickRequest cherryPickRequest = CherryPickRequestAllocatorTest.createCherryPickRequest(2, 10);
        ScreenerCherryPick dummyScreenerCherryPick = new ScreenerCherryPick(cherryPickRequest, 
                                                                            dao.findWell(new WellKey(1, "A01")));
        cherryPickRequest.setRandomizedAssayPlateLayout(false);
        Set<Integer> emptyColumns = new HashSet<Integer>();
        emptyColumns.addAll(Arrays.asList(4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22));
        cherryPickRequest.setRequestedEmptyColumnsOnAssayPlate(emptyColumns);
        addLabCherryPicks(dummyScreenerCherryPick, 1, "A01", "A14"); // to assay plate 1, col 3 and 8 (partially)
        addLabCherryPicks(dummyScreenerCherryPick, 2, "A01", "A08"); // to assay plate 1, col 8 (leaving 2 available)
        addLabCherryPicks(dummyScreenerCherryPick, 3, "A01", "A16"); // to assay plate 2
        addLabCherryPicks(dummyScreenerCherryPick, 4, "A01", "A08"); // to assay plate 2 (exactly full)
        addLabCherryPicks(dummyScreenerCherryPick, 5, "A01", "B02"); // C copies (23) to assay plate 3, D copies (3) to assay plate 4
        addLabCherryPicks(dummyScreenerCherryPick, 6, "A01", "A09"); // both C (3) and D copies (6) to assay plate 4
        assertEquals(81, cherryPickRequest.getLabCherryPicks().size());
        dao.persistEntity(cherryPickRequest.getScreen());
        cherryPickRequestAllocator.allocate(cherryPickRequest);
        cherryPickRequestPlateMapper.generatePlateMapping(cherryPickRequest);

        assertEquals("assay plates count", 4, cherryPickRequest.getCherryPickAssayPlates().size());
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 0, 21, 0);
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 22, 45, 1);
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 46, 68, 2);
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 69, 80, 3);
        
        CherryPickAssayPlate lastPlate = cherryPickRequest.getCherryPickAssayPlates().last();
        for (int iCol = 0; iCol < Well.PLATE_COLUMNS; iCol++) {
          if (iCol == 2) {
            assertColumnIsFull(cherryPickRequest, lastPlate, iCol);
          }
          else  {
            assertColumnIsEmpty(cherryPickRequest, lastPlate, iCol);
          }
        }
        
        assertFalse(cherryPickRequest.isSourcePlateReloadRequired());
      }
    });
  }
  
  /**
   * Tests the case where the wells from a single source plate are too numerous
   * to fit on even an empty assay plate (in which case we must map these wells
   * to two or more assay plates)
   */
  public void testTooManySourcePlateWellsForAssayPlate()
  {
    dao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction() {
        Library duplexLibrary = CherryPickRequestAllocatorTest.makeRNAiDuplexLibrary("Duplexes library", 1, 1, 384);
        makeLibraryCopy(duplexLibrary, "C", 10);
        dao.persistEntity(duplexLibrary);

        CherryPickRequest cherryPickRequest = CherryPickRequestAllocatorTest.createCherryPickRequest(1, 10);
        ScreenerCherryPick dummyScreenerCherryPick = new ScreenerCherryPick(cherryPickRequest, 
                                                                            dao.findWell(new WellKey(1, "A01")));
        cherryPickRequest.setRandomizedAssayPlateLayout(false);
        Set<Integer> emptyColumns = new HashSet<Integer>();
        emptyColumns.addAll(Arrays.asList(4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22));
        cherryPickRequest.setRequestedEmptyColumnsOnAssayPlate(emptyColumns);
        addLabCherryPicks(dummyScreenerCherryPick, 1, "A01", "B04"); // enough to fill 2 assay plates completely, plus a 3rd, partially
        assertEquals(28, cherryPickRequest.getLabCherryPicks().size());
        dao.persistEntity(cherryPickRequest.getScreen());
        cherryPickRequestAllocator.allocate(cherryPickRequest);
        cherryPickRequestPlateMapper.generatePlateMapping(cherryPickRequest);

        assertEquals("assay plates count", 3, cherryPickRequest.getCherryPickAssayPlates().size());
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 0, 11, 0);
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 12, 23, 1);
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 24, 27, 2);
        
        assertTrue(cherryPickRequest.isSourcePlateReloadRequired());
      }
    });
  }
  
  public void testRandomizedPlateMappingIsLeftConstrained()
  {
    dao.doInTransaction(new DAOTransaction()
    {
      public void runTransaction() {
        Library library = CherryPickRequestAllocatorTest.makeRNAiDuplexLibrary("library", 1, 1, 384);
        makeLibraryCopy(library, "C", 10);
        dao.persistEntity(library);

        CherryPickRequest cherryPickRequest = CherryPickRequestAllocatorTest.createCherryPickRequest(1, 10);
        ScreenerCherryPick dummyScreenerCherryPick = new ScreenerCherryPick(cherryPickRequest, dao.findWell(new WellKey(1, "A01")));
        cherryPickRequest.setRandomizedAssayPlateLayout(true);
        Set<Integer> emptyColumns = new HashSet<Integer>();
        emptyColumns.addAll(Arrays.asList(4)); // 1-based column number (4 is 3, below)
        cherryPickRequest.setRequestedEmptyColumnsOnAssayPlate(emptyColumns);
        addLabCherryPicks(dummyScreenerCherryPick, 1, "A01", "C24"); // create 72 cherry picks, to fill exactly 6 left-most available columns
        dao.persistEntity(cherryPickRequest.getScreen());
        cherryPickRequestAllocator.allocate(cherryPickRequest);
        cherryPickRequestPlateMapper.generatePlateMapping(cherryPickRequest);

        assertEquals("assay plates count", 1, cherryPickRequest.getCherryPickAssayPlates().size());
        assertLabCherryPicksOnAssayPlate(cherryPickRequest, 0, 71, 0);
        assertColumnIsFull(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 2);
        assertColumnIsFull(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 4);
        assertColumnIsFull(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 5);
        assertColumnIsFull(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 6);
        assertColumnIsFull(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 7);
        assertColumnIsFull(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 8);
        assertColumnIsEmpty(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 0);
        assertColumnIsEmpty(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 1);
        assertColumnIsEmpty(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), 3);
        for (int iCol = 9; iCol < Well.PLATE_COLUMNS; ++iCol) {
          assertColumnIsEmpty(cherryPickRequest, cherryPickRequest.getCherryPickAssayPlates().first(), iCol);
        }
      }
    });
  }

  private void assertColumnIsEmpty(CherryPickRequest cherryPickRequest, CherryPickAssayPlate assayPlate, int columnIndex)
  {
    for (LabCherryPick cherryPick : assayPlate.getLabCherryPicks()) {
      if (cherryPick.getAssayPlateColumn() == columnIndex) {
        fail("column " + columnIndex + " is empty on plate " + assayPlate.getName());
      }
    }
  }

  private void assertColumnIsFull(CherryPickRequest cherryPickRequest, CherryPickAssayPlate assayPlate, int columnIndex)
  {
    int cherryPicksInColumn = 0;
    for (LabCherryPick cherryPick : assayPlate.getLabCherryPicks()) {
      if (cherryPick.getAssayPlateColumn() == columnIndex) {
        ++cherryPicksInColumn;
      }
    }
    assertEquals("column " + columnIndex + " is full on plate " + assayPlate.getName(),
                 Well.PLATE_ROWS - cherryPickRequest.getRequiredEmptyRowsOnAssayPlate().size(),
                 cherryPicksInColumn);
  }

  private void addLabCherryPicks(ScreenerCherryPick screenerCherryPick,
                                 int libraryPlateNumber, 
                                 String firstWellNameStr, 
                                 String lastWellNameStr)
  {
    WellName firstWellName = new WellName(firstWellNameStr);
    WellName lastWellName = new WellName(lastWellNameStr);
    for (int iRow = firstWellName.getRowIndex(); iRow <= lastWellName.getRowIndex(); ++iRow) {
      int iColFirst;
      if (iRow == firstWellName.getRowIndex()) {
        iColFirst = firstWellName.getColumnIndex();
      } 
      else {
        iColFirst = Well.MIN_WELL_COLUMN - 1;
      }
      int iColLast;
      if (iRow == lastWellName.getRowIndex()) {
        iColLast = lastWellName.getColumnIndex();
      } 
      else {
        iColLast = Well.MAX_WELL_COLUMN - 1;
      }
      for (int iCol = iColFirst; iCol <= iColLast; ++iCol) {
        new LabCherryPick(screenerCherryPick,
                          dao.findWell(new WellKey(libraryPlateNumber, new WellName(iRow, iCol))));
      }
    }
  }


  // private methods

  private void assertLabCherryPicksOnAssayPlate(CherryPickRequest cherryPickRequest, 
                                             int firstIndex, 
                                             int lastIndex, 
                                             int expectedAssayPlateIndex)
  {
    TreeSet<LabCherryPick> sortedCherryPicks = new TreeSet<LabCherryPick>(PlateMappingCherryPickComparator.getInstance());
    sortedCherryPicks.addAll(cherryPickRequest.getLabCherryPicks());
    List<LabCherryPick> indexedCherryPicks = new ArrayList<LabCherryPick>(sortedCherryPicks);
    for (int index = firstIndex; index <= lastIndex; index++) {
      String expectedAssayPlateName = String.format("Cherry Picker (%d) CP%d  Plate %02d of %d",
                                                    cherryPickRequest.getScreen().getScreenNumber(),
                                                    cherryPickRequest.getEntityId(),
                                                    expectedAssayPlateIndex + 1,
                                                    cherryPickRequest.getCherryPickAssayPlates().size());
      LabCherryPick cherryPick = indexedCherryPicks.get(index);
      assertEquals("cherry pick #" + index + " assay plate name",
                   expectedAssayPlateName,
                   cherryPick.getAssayPlate().getName());
    }
  }

  private void makeLibraryCopy(Library library, String copyName, int volume)
  {
    Copy copy = new Copy(library, CopyUsageType.FOR_CHERRY_PICK_SCREENING, copyName);
    for (int plateNumber = library.getStartPlate(); plateNumber <= library.getEndPlate(); plateNumber++) {
      new CopyInfo(copy, plateNumber, "<loc>", PlateType.EPPENDORF, new BigDecimal(volume));      
    }
  }
}

