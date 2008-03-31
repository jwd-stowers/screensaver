// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.io.libraries;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import edu.harvard.med.screensaver.AbstractSpringPersistenceTest;
import edu.harvard.med.screensaver.db.DAOTransaction;
import edu.harvard.med.screensaver.db.LibrariesDAO;
import edu.harvard.med.screensaver.db.datafetcher.EntityDataFetcher;
import edu.harvard.med.screensaver.db.datafetcher.EntitySetDataFetcher;
import edu.harvard.med.screensaver.model.RelationshipPath;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.libraries.LibraryType;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.screens.ScreenType;

import org.apache.log4j.Logger;

public class WellsSdfDataExporterTest extends AbstractSpringPersistenceTest
{
  private static Logger log = Logger.getLogger(WellsSdfDataExporterTest.class);

  protected LibrariesDAO librariesDao;

  class WellListDAOTransaction implements DAOTransaction
  {
    Set<Well> wellSet = new HashSet<Well>();
    public void runTransaction()
    {
      Library library = new Library(
        "dummy",
        "shortDummy",
        ScreenType.SMALL_MOLECULE,
        LibraryType.COMMERCIAL,
        1,
        1);
      genericEntityDao.saveOrUpdateEntity(library);
      librariesDao.loadOrCreateWellsForLibrary(library);
      wellSet = library.getWells();
    }
  }

  public void testExportWellsDataToSDF()
  {
    assertNotNull(librariesDao);
    WellsSdfDataExporter wellsDataExporter =
      new WellsSdfDataExporter(genericEntityDao);
    WellListDAOTransaction wellListDAOTransaction = new WellListDAOTransaction();
    genericEntityDao.doInTransaction(wellListDAOTransaction);
    
    // for now, just run the export method and make sure that it doesnt fail
    Set<String> wellKeys = new HashSet<String>();
    wellKeys.add("00001:A01");
    wellKeys.add("00001:A02");
    wellKeys.add("00001:A03");
    EntityDataFetcher<Well,String> dataFetcher = new EntitySetDataFetcher<Well,String>(Well.class, wellKeys, genericEntityDao);
    wellsDataExporter.export(dataFetcher);
  }
}
