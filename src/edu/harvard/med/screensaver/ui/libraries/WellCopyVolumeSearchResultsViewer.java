// $HeadURL: svn+ssh://ant4@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.settings/org.eclipse.jdt.ui.prefs $
// $Id: org.eclipse.jdt.ui.prefs 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.libraries;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import edu.harvard.med.screensaver.ui.control.LibrariesController;
import edu.harvard.med.screensaver.ui.searchresults.SearchResults;
import edu.harvard.med.screensaver.ui.searchresults.SearchResultsViewer;

import org.apache.commons.collections.MultiMap;
import org.apache.commons.collections.map.MultiValueMap;

/**
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 */
public class WellCopyVolumeSearchResultsViewer extends SearchResultsViewer<WellCopyVolume>
{
  private LibrariesController _librariesController;
  private WellVolumeSearchResults _wellVolumeSearchResults;


  public void setLibrariesController(LibrariesController librariesController)
  {
    _librariesController = librariesController;
  }

  @Override
  @SuppressWarnings("unchecked")
  public void setSearchResults(SearchResults<WellCopyVolume> wellCopyVolumeSearchResults)
  {
    super.setSearchResults(wellCopyVolumeSearchResults);
    
    MultiMap wellKey2WellCopyVolumes = new MultiValueMap();
    for (WellCopyVolume wellCopyVolume : wellCopyVolumeSearchResults.getContents()) {
      wellKey2WellCopyVolumes.put(wellCopyVolume.getWell().getWellKey(),
                                  wellCopyVolume);
    }

    List<WellVolume> wellVolumes = new ArrayList<WellVolume>();
    for (Iterator iter = wellKey2WellCopyVolumes.keySet().iterator(); iter.hasNext(); ) {
      List<WellCopyVolume> wellCopyVolumes = (List<WellCopyVolume>) wellKey2WellCopyVolumes.get(iter.next());
      wellVolumes.add(new WellVolume(wellCopyVolumes.get(0).getWell(),
                                     wellCopyVolumes));
    }
    _wellVolumeSearchResults = new WellVolumeSearchResults(wellVolumes, _librariesController);
  }

  public WellVolumeSearchResults getWellVolumeSearchResults()
  {
    return _wellVolumeSearchResults;
  }
}