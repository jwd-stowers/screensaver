// $HeadURL$
// $Id$
//
// Copyright © 2006, 2010, 2011, 2012 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.db.accesspolicy;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.BeanFactory;
import org.springframework.beans.factory.BeanFactoryAware;

import edu.harvard.med.screensaver.db.AbstractManagedEventsListener;
import edu.harvard.med.screensaver.model.AbstractEntity;
import edu.harvard.med.screensaver.policy.EntityViewPolicy;

/**
 * A Hibernate event listener that injects the specified EntityViewPolicy into
 * every AbstractEntity object loaded by Hibernate.
 * 
 * @see AbstractEntity#isRestricted()
 * 
 * @author <a mailto="andrew_tolopko@hms.harvard.edu">Andrew Tolopko</a>
 */
// HACK: we're forced to make this a BeanFactoryAware bean, in order to obtain an
// EntityViewPolicy without creating a circular dependency in Spring
// configuration files (and using the Spring-recommended setter-based injection
// strategy for handling circular dependencies could not be made to work).
// TODO: remove "PostLoadEventListener" suffix from this class name
public class EntityViewPolicyInjectorPostLoadEventListener extends AbstractManagedEventsListener implements BeanFactoryAware
{
  private static final long serialVersionUID = 1L;

  private BeanFactory _beanFactory;
  private EntityViewPolicy _entityViewPolicy;
  
  public void setBeanFactory(BeanFactory beanFactory) throws BeansException
  {
    _beanFactory = beanFactory;
  }
  
  public EntityViewPolicy getEntityViewPolicy()
  {
    if (_entityViewPolicy == null) {
      _entityViewPolicy = (EntityViewPolicy) _beanFactory.getBean("entityViewPolicy");
    }
    return _entityViewPolicy;
  }

  public void apply(Object entity)
  {
    if (entity instanceof AbstractEntity) {
      ((AbstractEntity) entity).setEntityViewPolicy(getEntityViewPolicy());
    }
  }
}

