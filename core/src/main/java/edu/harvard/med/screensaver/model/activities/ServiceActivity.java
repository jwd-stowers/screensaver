// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
//
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.model.activities;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.PrimaryKeyJoinColumn;
import javax.persistence.Transient;

import org.apache.log4j.Logger;
import org.joda.time.LocalDate;

import edu.harvard.med.screensaver.model.AbstractEntityVisitor;
import edu.harvard.med.screensaver.model.meta.Cardinality;
import edu.harvard.med.screensaver.model.meta.RelationshipPath;
import edu.harvard.med.screensaver.model.screens.FundingSupport;
import edu.harvard.med.screensaver.model.screens.Screen;
import edu.harvard.med.screensaver.model.screens.ScreenType;
import edu.harvard.med.screensaver.model.users.AdministratorUser;
import edu.harvard.med.screensaver.model.users.ScreeningRoomUser;

/**
 */
@Entity
@PrimaryKeyJoinColumn(name="activityId")
@org.hibernate.annotations.ForeignKey(name = "fk_service_activity_to_activity")
@org.hibernate.annotations.Proxy
public class ServiceActivity extends TypedActivity<ServiceActivityType>
{
  private static Logger log = Logger.getLogger(ServiceActivity.class);
  
  private static final long serialVersionUID = 1L;

  public static final ServiceActivity Null = new ServiceActivity();

  public static final RelationshipPath<ServiceActivity> servicedUser = 
      RelationshipPath.from(ServiceActivity.class).to("servicedUser", Cardinality.TO_ONE);
  public static final RelationshipPath<ServiceActivity> servicedScreen = 
      RelationshipPath.from(ServiceActivity.class).to("servicedScreen", Cardinality.TO_ONE);

  private Screen _servicedScreen;
  private ScreeningRoomUser _servicedUser;
  private FundingSupport _fundingSupport;

  /**
   * @motivation for hibernate and proxy/concrete subclass constructors
   */
  protected ServiceActivity()
  {}

  public ServiceActivity(AdministratorUser recordedBy,
                         AdministratorUser performedBy,
                         LocalDate dateOfActivity,
                         ServiceActivityType type,
                         ScreeningRoomUser servicedUser)
  {
    super(recordedBy, performedBy, dateOfActivity, type);
    _servicedUser = servicedUser;
    // performedBy.getActivitiesPerformed().add(this);
  }

  @Override
  public Object acceptVisitor(AbstractEntityVisitor visitor)
  {
    return visitor.visit(this);
  }

  @Column(name = "serviceActivityType", nullable = false)
  @org.hibernate.annotations.Type(type = "edu.harvard.med.screensaver.model.activities.ServiceActivityType$UserType")
  public ServiceActivityType getType()
  {
    return _type;
  }

  @Override
  public void setType(ServiceActivityType type)
  {
    _type = type;
  }
  
  @ManyToOne(cascade={ CascadeType.PERSIST, CascadeType.MERGE })
  @JoinColumn(name="fundingSupportId", nullable=true)
  @org.hibernate.annotations.ForeignKey(name="fk_service_activity_to_funding_support")
//  @org.hibernate.annotations.LazyToOne(value=org.hibernate.annotations.LazyToOneOption.PROXY)
  @edu.harvard.med.screensaver.model.annotations.ToOne(unidirectional=true)
  public FundingSupport getFundingSupport()
  {
    return _fundingSupport;
  }

  public void setFundingSupport(FundingSupport fundingSupport)
  {
    _fundingSupport = fundingSupport;
  }
  

  /**
   * The screen for which this service was performed (optional).
   */
  @ManyToOne(cascade = { CascadeType.PERSIST, CascadeType.MERGE })
  @JoinColumn(name = "serviced_screen_id", nullable = true)
  @org.hibernate.annotations.LazyToOne(value=org.hibernate.annotations.LazyToOneOption.PROXY)
  @edu.harvard.med.screensaver.model.annotations.ToOne(inverseProperty="serviceActivities")
  public Screen getServicedScreen()
  {
    return _servicedScreen;
  }

  public void setServicedScreen(Screen screen)
  {
    _servicedScreen = screen;
  }

  /**
   * The user to which this service was provided.
   */
  @ManyToOne(cascade = { CascadeType.PERSIST, CascadeType.MERGE })
  @JoinColumn(name = "serviced_user_id", nullable = false)
  @edu.harvard.med.screensaver.model.annotations.ToOne(unidirectional = true)
  public ScreeningRoomUser getServicedUser()
  {
    return _servicedUser;
  }

  private void setServicedUser(ScreeningRoomUser user)
  {
    _servicedUser = user;
  }
}
