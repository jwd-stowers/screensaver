// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/branches/schema-upgrade-2007/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.table.model;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import junit.framework.TestCase;

import edu.harvard.med.screensaver.db.SortDirection;
import edu.harvard.med.screensaver.db.datafetcher.EntityDataFetcher;
import edu.harvard.med.screensaver.db.hibernate.HqlBuilder;
import edu.harvard.med.screensaver.model.MakeDummyEntities;
import edu.harvard.med.screensaver.model.PropertyPath;
import edu.harvard.med.screensaver.model.RelationshipPath;
import edu.harvard.med.screensaver.model.libraries.Library;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.ui.table.column.ColumnType;
import edu.harvard.med.screensaver.ui.table.column.entity.EntityColumn;
import edu.harvard.med.screensaver.ui.util.ValueReference;

import org.apache.log4j.Logger;


public class VirtualPagingEntityDataModelTest extends TestCase
{
  private static Logger log = Logger.getLogger(VirtualPagingEntityDataModelTest.class);
  
  final class MockEntityDataFetcher extends EntityDataFetcher<Well,String>
  {
    public int _findAllKeysCount;
    public int _fetchAllDataCount;
    public int _fetchDataCount;
    private Library _library;
    private Map<String,Well> _wells = new HashMap<String,Well>();
    

    MockEntityDataFetcher()
    {
      super(Well.class, null);
      _library = MakeDummyEntities.makeDummyLibrary(1, ScreenType.SMALL_MOLECULE, 1);
      for (Well well : _library.getWells()) {
        _wells.put(well.getWellKey().toString(), well);
      }
    }

    @Override
    protected void addDomainRestrictions(HqlBuilder hql,
                                         Map<RelationshipPath<Well>,String> path2Alias)
    {
    }

    @Override
    public List<String> findAllKeys()
    {
      ++_findAllKeysCount;
      return new ArrayList<String>(_wells.keySet()); 
    }

    @Override
    public List<Well> fetchAllData()
    {
      ++_fetchAllDataCount;
      return new ArrayList<Well>(_wells.values());
    }

    @Override
    public Map<String,Well> fetchData(Set<String> keys)
    {
      ++_fetchDataCount;
      Map<String,Well> result = new HashMap<String,Well>();
      for (String key : keys) {
        result.put(key, _wells.get(key));
      }
      return result;
    }
  }

  public void testNoQueryOnOnlySortDirectionChange()
  {
    MockEntityDataFetcher fetcher = new MockEntityDataFetcher();
    
    EntityColumn<Well,String> column1 = new EntityColumn<Well,String>(new PropertyPath<Well>(Well.class, "id"), "column1", "", ColumnType.TEXT, "") {
      @Override
      public String getCellValue(Well row) { return row.getWellKey().toString(); }
    };
    EntityColumn<Well,String> column2 = new EntityColumn<Well,String>(new PropertyPath<Well>(Well.class, "smiles"), "column2", "", ColumnType.TEXT, "") {
      @Override
      public String getCellValue(Well row) { return row.getSmiles(); }
    };

    ValueReference<Integer> rowsToFetch = new ValueReference<Integer>() { public Integer value() { return 10; } };
    VirtualPagingEntityDataModel<String,Well> model = new VirtualPagingEntityDataModel<String,Well>(fetcher, rowsToFetch);
    
    int prevFetchAllKeysCount = fetcher._findAllKeysCount;
    model.sort(Arrays.asList(column1), SortDirection.ASCENDING);
    model.setRowIndex(0); model.getRowData();
    assertEquals("query on initial sort", prevFetchAllKeysCount + 1, fetcher._findAllKeysCount);
    model.sort(Arrays.asList(column2), SortDirection.ASCENDING);
    model.setRowIndex(0); 
    model.getRowData();
    assertEquals("query on sort column changed", prevFetchAllKeysCount + 2, fetcher._findAllKeysCount);
    model.sort(Arrays.asList(column2), SortDirection.DESCENDING);
    model.setRowIndex(0); model.getRowData();
    assertEquals("no query on only sort direction changed", prevFetchAllKeysCount + 2, fetcher._findAllKeysCount);
  }

}