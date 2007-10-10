// $HeadURL: svn+ssh://js163@orchestra.med.harvard.edu/svn/iccb/screensaver/trunk/.eclipse.prefs/codetemplates.xml $
// $Id: codetemplates.xml 169 2006-06-14 21:57:49Z js163 $
//
// Copyright 2006 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.model.cherrypicks;

import java.math.BigDecimal;
import java.util.Date;
import java.util.HashSet;
import java.util.Set;

import javax.persistence.Entity;
import javax.persistence.PrimaryKeyJoinColumn;
import javax.persistence.Transient;

import org.apache.log4j.Logger;

import edu.harvard.med.screensaver.model.AbstractEntityVisitor;
import edu.harvard.med.screensaver.model.libraries.Compound;
import edu.harvard.med.screensaver.model.libraries.PlateType;
import edu.harvard.med.screensaver.model.libraries.Well;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;

/**
 * A hibernate entity representing a compound cherry pick request.
 *
 * @author <a mailto="john_sullivan@hms.harvard.edu">John Sullivan</a>
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
@Entity
@PrimaryKeyJoinColumn(name="cherryPickRequestId")
@org.hibernate.annotations.ForeignKey(name="fk_compound_cherry_pick_request_to_cherry_pick_request")
@org.hibernate.annotations.Proxy
public class CompoundCherryPickRequest extends CherryPickRequest
{

  // private static data

  private static final long serialVersionUID = 1L;
  private static Logger log = Logger.getLogger(CompoundCherryPickRequest.class);
  private static final PlateType COMPOUND_CHERRY_PICK_ASSAY_PLATE_TYPE = PlateType.ABGENE;
  private static final BigDecimal SOURCE_WELL_COUNT_PCT_LIMIT = new BigDecimal("0.003");


  // public constructor

  /**
   * Construct an initialized <code>CompoundCherryPickRequest</code>. Intended only for use
   * by {@link Screen#createCherryPickRequest(ScreeningRoomUser, Date, Integer)}.
   * @param screen the screen
   * @param requestedBy the user that made the request
   * @param dateRequested the date created
   * @param legacyId the legacy id from ScreenDB
   * @motivation for creating CherryPickRequests from legacy ScreenDB cherry pick visits
   */
  public CompoundCherryPickRequest(
    Screen screen,
    ScreeningRoomUser requestedBy,
    Date dateRequested,
    Integer legacyCherryPickRequestNumber)
  {
    super(screen, requestedBy, dateRequested, legacyCherryPickRequestNumber);
  }


  // public instance methods

  @Override
  public Object acceptVisitor(AbstractEntityVisitor visitor)
  {
    return visitor.visit(this);
  }

  @Override
  @Transient
  public PlateType getAssayPlateType()
  {
    return COMPOUND_CHERRY_PICK_ASSAY_PLATE_TYPE;
  }

  /**
   * For compound screens, the cherry pick limit
   * is 0.3% of the number of distinct compounds selected (and not wells, which may have
   * overlapping compounds).
   */
  @Override
  @Transient
  public int getCherryPickAllowance()
  {
    Set<Compound> distinctCompounds = new HashSet<Compound>(getScreenerCherryPicks().size());
    for (Well well : getScreen().getScreenResult().getWells()) {
      distinctCompounds.add(well.getPrimaryCompound());
    }
    return SOURCE_WELL_COUNT_PCT_LIMIT.multiply(new BigDecimal(distinctCompounds.size())).intValue();
  }

  @Override
  @Transient
  public int getCherryPickAllowanceUsed()
  {
    return getScreenerCherryPicks().size();
  }


  // protected constructor

  /**
   * Construct an uninitialized <code>CompoundCherryPickRequest</code>.
   * @motivation for hibernate and proxy/concrete subclass constructors
   */
  protected CompoundCherryPickRequest() {}
}
