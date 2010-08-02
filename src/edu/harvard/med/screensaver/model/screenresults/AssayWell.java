// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.model.screenresults;

import java.util.HashMap;
import java.util.Map;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;
import javax.persistence.Version;

import org.apache.log4j.Logger;

import edu.harvard.med.screensaver.model.AbstractEntity;
import edu.harvard.med.screensaver.model.AbstractEntityVisitor;
import edu.harvard.med.screensaver.model.DataModelViolationException;
import edu.harvard.med.screensaver.model.annotations.ContainedEntity;
import edu.harvard.med.screensaver.model.annotations.ToOne;
import edu.harvard.med.screensaver.model.libraries.LibraryWellType;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.meta.Cardinality;
import edu.harvard.med.screensaver.model.meta.RelationshipPath;


/**
 * AssayWell maintains information common to each ResultValue of a given library Well.
 *
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
@Entity
@org.hibernate.annotations.Entity
@org.hibernate.annotations.Proxy
@Table(uniqueConstraints = { @UniqueConstraint(columnNames = { "screenResultId", "well_id" }) })
@ContainedEntity(containingEntityClass=ScreenResult.class)                                 
public class AssayWell extends AbstractEntity<Integer> implements Comparable<AssayWell>
{
  private static final long serialVersionUID = 1L;
  private static final Logger log = Logger.getLogger(AssayWell.class);
  
  public static final RelationshipPath<AssayWell> screenResult = RelationshipPath.from(AssayWell.class).to("screenResult", Cardinality.TO_ONE);
  public static final RelationshipPath<AssayWell> libraryWell = RelationshipPath.from(AssayWell.class).to("libraryWell", Cardinality.TO_ONE);

  private Integer _version;
  private ScreenResult _screenResult;
  private Well _libraryWell;
  private AssayWellControlType _assayWellControlType;
  private boolean _isPositive;
  private Map<DataColumn,ResultValue> _resultValues = new HashMap<DataColumn,ResultValue>();


  /*public*/ AssayWell(ScreenResult screenResult, Well libraryWell)
  {
    if (screenResult == null) {
      throw new DataModelViolationException("screenResult is required");
    }
    if (libraryWell == null) {
      throw new DataModelViolationException("screenResult is required");
    }
    _screenResult = screenResult;
    _libraryWell = libraryWell;
//    // TODO: remove, for performance of screen result import
//    _libraryWell.getAssayWells().put(_screenResult, this);
  }

  @Override
  public Object acceptVisitor(AbstractEntityVisitor visitor)
  {
    return visitor.visit(this);
  }

  @Id
  @org.hibernate.annotations.GenericGenerator(
    name="assay_well_id_seq",
    strategy="seqhilo",
    parameters = {
      @org.hibernate.annotations.Parameter(name="sequence", value="assay_well_id_seq"),
      @org.hibernate.annotations.Parameter(name="max_lo", value="384")
    }
  )
  @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="assay_well_id_seq")
  public Integer getAssayWellId()
  {
    return getEntityId();
  }

  /**
   * Get the version number of the screen result.
   * @return the version number of the screen result
   * @motivation for hibernate
   */
  @Column(nullable=false)
  @Version
  private Integer getVersion()
  {
    return _version;
  }

  /**
   * Set the version number of the screen result.
   * @param version the new version number of the screen result
   * @motivation for hibernate
   */
  private void setVersion(Integer version)
  {
    _version = version;
  }

  public int compareTo(AssayWell other)
  {
    return getLibraryWell().getWellKey().compareTo(((AssayWell) other).getLibraryWell().getWellKey());
  }

  @ManyToOne(fetch=FetchType.LAZY, cascade={})
  @JoinColumn(name="screenResultId", nullable=false, updatable=false)
  @org.hibernate.annotations.Immutable
  @org.hibernate.annotations.ForeignKey(name="fk_assay_well_to_screen_result")
  @org.hibernate.annotations.LazyToOne(value=org.hibernate.annotations.LazyToOneOption.PROXY)
  public ScreenResult getScreenResult()
  {
    return _screenResult;
  }

  private void setScreenResult(ScreenResult screenResult)
  {
    _screenResult = screenResult;
  }

  /**
   * Get the well.
   * @return the well
   */
  @ManyToOne(fetch=FetchType.LAZY, cascade={} /*Well is owned by Library.wells*/)
  @JoinColumn(name="well_id", nullable=false, updatable=false)
  @org.hibernate.annotations.Immutable
  @org.hibernate.annotations.ForeignKey(name="fk_assay_well_to_well")
  @org.hibernate.annotations.LazyToOne(value=org.hibernate.annotations.LazyToOneOption.PROXY)
  @ToOne(unidirectional=true)
  public Well getLibraryWell()
  {
    return _libraryWell;
  }

  /**
   * @motivation for hibernate
   */
  private void setLibraryWell(Well libraryWell)
  {
    _libraryWell = libraryWell;
  }

  /**
   * Get whether this assay well contains at least one {@link ResultValue} that
   * is a {@link ResultValue#isPositive() positive}.
   */
  @Column(nullable=false, name="isPositive")
  @org.hibernate.annotations.Index(name="assay_well_well_positives_only_index")
  public boolean isPositive()
  {
    return _isPositive;
  }

  // TODO
//  private void setResultValues(Map<DataColumn,ResultValue> resultValues)
//  {
//    _resultValues = resultValues;
//  }
//
//  /**
//   * Get the set of result values.
//   * @return the set of result values
//   */
//  @OneToMany(fetch=FetchType.LAZY, mappedBy="assayWell")
//  @MapKeyManyToMany(joinColumns={ @JoinColumn(name="dataColumnId") }, targetEntity=DataColumn.class)
//  public Map<DataColumn,ResultValue> getResultValues()
//  {
//    return _resultValues;
//  }

  public void setPositive(boolean isPositive)
  {
    _isPositive = isPositive;
  }

  /**
   * Get the assay well's type.
   *
   * @return the assay well's type
   */
  @Column(nullable=true)
  @org.hibernate.annotations.Type(type="edu.harvard.med.screensaver.model.screenresults.AssayWellControlType$UserType")
  public AssayWellControlType getAssayWellControlType()
  {
    return _assayWellControlType;
  }

  public void setAssayWellControlType(AssayWellControlType assayWellControlType)
  {
    if (!isHibernateCaller() &&
      assayWellControlType != null &&
      _libraryWell.getLibraryWellType() != LibraryWellType.EMPTY &&
      _libraryWell.getLibraryWellType() != LibraryWellType.DMSO) {
      throw new DataModelViolationException("assay well control type can only be defined if the library well type is 'empty' or 'DMSO'");
    }
    _assayWellControlType = assayWellControlType;
  }

  /**
   * @motivation for hibernate
   */
  protected AssayWell() {}

  /**
   * Set the well id for the well.
   * @param wellId the new well id for the well
   * @motivation for hibernate
   */
  private void setAssayWellId(Integer assayWellId)
  {
    setEntityId(assayWellId);
  }
}
