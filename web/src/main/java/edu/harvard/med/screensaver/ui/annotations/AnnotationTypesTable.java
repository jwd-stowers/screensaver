// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.ui.annotations;

import java.util.Arrays;
import java.util.List;

import edu.harvard.med.screensaver.model.screenresults.AnnotationType;
import edu.harvard.med.screensaver.ui.screenresults.MetaDataTable;

public class AnnotationTypesTable extends MetaDataTable<AnnotationType>
{
  // TODO: consider replacing MetaDataTableRowDefinition with TableColumn<AnnotationType>
  @SuppressWarnings("unchecked")
  private final List<MetaDataTableRowDefinition<AnnotationType>> ANNOTATION_TYPE_ROW_DEFINTIIONS =
    Arrays.asList
    (
     new MetaDataTableRowDefinition<AnnotationType>("description", "Description", "A description of the data column"),
     new MetaDataTableRowDefinition<AnnotationType>("numeric", "Numeric", "Whether the annotation type has numeric data")
    );

  @Override
  protected List<MetaDataTableRowDefinition<AnnotationType>> getMetaDataTableRowDefinitions()
  {
    return ANNOTATION_TYPE_ROW_DEFINTIIONS;
  }
}

