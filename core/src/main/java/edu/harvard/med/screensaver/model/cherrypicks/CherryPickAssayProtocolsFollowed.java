// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.model.cherrypicks;

import edu.harvard.med.screensaver.model.VocabularyTerm;
import edu.harvard.med.screensaver.model.VocabularyUserType;

public enum CherryPickAssayProtocolsFollowed implements VocabularyTerm 
{
  SAME_PROTOCOL_AS_PRIMARY_ASSAY("Same protocol as primary assay"),
  SAME_PROTOCOL_AS_PRIMARY_ASSAY_AND_NEW_ASSAY_PROTOCOLS("Same protocol as primary assay and new assay protocols"),
  NEW_ASSAY_PROTCOLS_ONLY("New assay protocols only");
  
  /**
   * A Hibernate <code>UserType</code> to map the {@link CherryPickAssayProtocolsFollowed} vocabulary.
   */
  public static class UserType extends VocabularyUserType<CherryPickAssayProtocolsFollowed>
  {
    public UserType()
    {
      super(CherryPickAssayProtocolsFollowed.values());
    }
  }


  private String _value;

  private CherryPickAssayProtocolsFollowed(String value)
  {
    _value = value;
  }

  /**
   * Get the value of the vocabulary term.
   * @return the value of the vocabulary term
   */
  public String getValue()
  {
    return _value;
  }

  @Override
  public String toString()
  {
    return getValue();
  }
}
