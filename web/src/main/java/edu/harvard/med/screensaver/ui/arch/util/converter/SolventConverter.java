// $HeadURL:
// http://forge.abcd.harvard.edu/svn/screensaver/branches/iccbl/2.2.2-dev/src/edu/harvard/med/screensaver/ui/util/SolventConverter.java
// $
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.arch.util.converter;

import edu.harvard.med.screensaver.model.libraries.Solvent;

public class SolventConverter extends VocabularyConverter<Solvent>
{
  public SolventConverter()
  {
    super(Solvent.values());
  }
}
