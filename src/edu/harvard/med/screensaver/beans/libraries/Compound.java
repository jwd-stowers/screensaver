// $HeadURL$
// $Id$
//
// Copyright 2006 by the President and Fellows of Harvard College.
// 
// Screensaver is an open-source project developed by the ICCB-L and NSRB labs
// at Harvard Medical School. This software is distributed under the terms of
// the GNU General Public License.

package edu.harvard.med.screensaver.beans.libraries;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;


/**
 * A Hibernate entity bean representing a molecular compound.
 * 
 * @author john sullivan
 * @hibernate.class
 */
public class Compound
{
  
  // instance fields
  
	private Integer     _compoundId;
  private Integer     _version;
  private Set<Well>   _wells = new HashSet<Well>();
	private String      _compoundName;
	private String      _smiles;
  private boolean     _isSalt;
  private Set<String> _synonyms = new HashSet<String>();
  private Set<String> _casNumbers = new HashSet<String>();
  private Set<String> _nscNumbers = new HashSet<String>();
  private String      _pubchemCid;
  private String      _chembankId;
	
  
  // public getters and setters
  
	/**
   * Get the compound id for the compound.
	 * @return the compound id for the compound
   * 
	 * @hibernate.id
   *   column="compound_id"
   *   generator-class="sequence"
   * @hibernate.generator-param
   *   name="sequence"
   *   value="compound_id_seq"
   */
	public Integer getCompoundId() {
		return _compoundId;
	}
  
  /**
   * Get the set of wells that contain this compound.
   * @return the set of wells that contain this compound
   *
   * @hibernate.set
   *   inverse="true"
   *   table="well_compound_link"
   *   lazy="true"
   *   cascade="save-update"
   * @hibernate.collection-key
   *   column="compound_id"
   * @hibernate.collection-many-to-many
   *   column="well_id"
   *   class="edu.harvard.med.screensaver.beans.libraries.Well"
   *   foreign-key="fk_well_compound_link_to_compound"
   */
  public Set<Well> getWells() {
    return Collections.unmodifiableSet(_wells);
  }

  /**
   * Add this compound to a well.
   * @param well the well to add this compound to
   * @return     true iff the compound was not already contained in the well
   */
  public boolean addWell(Well well) {
    well.getModifiableCompoundSet().add(this);
    return _wells.add(well);
  }
  
  /**
   * Remove this compound from a well.
   * @param well the well to remove this compound from
   * @return     true iff the compound was previously contained in the well
   */
  public boolean removeWell(Well well) {
    well.getModifiableCompoundSet().remove(this);
    return _wells.remove(well);
  }
  
  /**
   * Get the compound name
   * @return the compound name
   * 
   * @hibernate.property
   *   type="text"
   *   not-null="true"
   *   unique="true"
   *   column="compound_name"
   */
  public String getCompoundName() {
    return _compoundName;
  }

  /**
   * Set the compound name.
   * @param compoundName the new name for the compound
   */
  public void setCompoundName(String compoundName) {
    _compoundName = compoundName;
  }

  /**
   * Get the SMILES string for the compound.
   * @return the SMILES string for the compound
   * 
   * @hibernate.property
   *   type="text"
   *   unique="true"
   */
  public String getSmiles() {
    return _smiles;
  }

  /**
   * Set the SMILES string for the compound.
   * @param smiles the new SMILES string for the compound
   */
  public void setSmiles(String smiles) {
    _smiles = smiles;
  }

  /**
   * Get the saltiness of the compound.
   * @return true iff the compound is a salt
   * 
   * @hibernate.property
   *   column="is_salt"
   *   not-null="true"
   */
  public boolean isSalt() {
    return _isSalt;
  }

  /**
   * Set the saltiness of the compound.
   * @param isSalt the new saltiness for the compound
   */
  public void setSalt(boolean isSalt) {
    _isSalt = isSalt;
  }

  /**
   * Get the set of synonyms for the compound.
   * @return the set of synonyms for the compound
   *
   * @hibernate.set
   *   order-by="synonym"
   *   table="compound_synonym"
   *   cascade="delete"
   *   lazy="true"
   * @hibernate.collection-key
   *   column="compound_id"
   *   foreign-key="fk_compound_synonym_to_compound"
   * @hibernate.collection-element
   *   type="text"
   *   column="synonym"
   *   not-null="true"
   */
  public Set<String> getSynonyms() {
    return Collections.unmodifiableSet(_synonyms);
  }

  /**
   * Add a synonym for the compound.
   * @param synonym the synonym to add to the compound
   * @return        true iff the compound did not already have the synonym
   */
  public boolean addSynonym(String synonym) {
    return _synonyms.add(synonym);
  }

  /**
   * Remove a synonym from the compound.
   * @param synonym the synonym to remove from the compound
   * @return        true iff the compound previously had the synonym
   */
  public boolean removeSynonym(String synonym) {
    return _synonyms.remove(synonym);
  }

  /**
   * Get the set of CAS numbers for the compound.
   * @return the set of CAS numbers for the compound
   * 
   * @hibernate.set
   *   order-by="cas_number"
   *   table="compound_cas_number"
   *   cascade="delete"
   *   lazy="true"
   * @hibernate.collection-key
   *   column="compound_id"
   *   foreign-key="fk_compound_cas_number_to_compound"
   * @hibernate.collection-element
   *   type="text"
   *   column="cas_number"
   *   not-null="true"
   */
  public Set<String> getCasNumbers() {
    return Collections.unmodifiableSet(_casNumbers);
  }

  /**
   * Add a CAS number to the compound.
   * @param casNumber the CAS number to add to the compound
   * @return          true iff the compound did not already have the CAS number
   */
  public boolean addCasNumber(String casNumber) {
    return _casNumbers.add(casNumber);
  }

  /**
   * Remove a CAS number from the compound.
   * @param casNumber the CAS number to remove from the compound
   * @return          true iff the compound previously had the CAS number
   */
  public boolean removeCasNumber(String casNumber) {
    return _casNumbers.remove(casNumber);
  }

  /**
   * Get the set of NSC numbers for the compound.
   * @return the set of NSC numbers for the compound
   * 
   * @hibernate.set
   *   order-by="nsc_number"
   *   table="compound_nsc_number"
   *   cascade="delete"
   *   laxy="true"
   * @hibernate.collection-key
   *   column="compound_id"
   *   foreign-key="fk_compound_nsc_number_to_compound"
   * @hibernate.collection-element
   *   type="text"
   *   column="nsc_number"
   *   not-null="true"
   */
  public Set<String> getNscNumbers() {
    return Collections.unmodifiableSet(_nscNumbers);
  }

  /**
   * Add an NSC number to the compound.
   * @param nscNumber the NSC number to add to the compound
   * @return          true iff the compound did not already have the NSC number
   */
  public boolean addNscNumber(String nscNumber) {
    return _nscNumbers.add(nscNumber);
  }
  
  /**
   * Remove an NSC number from the compound.
   * @param nscNumber the NSC number to remove from the compound
   * @return          true iff the compound previously had the NSC number
   */
  public boolean removeNscNumber(String nscNumber) {
    return _nscNumbers.remove(nscNumber);
  }

  /**
   * Get the PubChem CID for the compound.
   * @return the PubChem CID for the compound
   *  
   * @hibernate.property
   *   type="text"
   *   column="pubchem_cid"
   */
  public String getPubchemCid() {
    return _pubchemCid;
  }

  /**
   * Set the PubChem CID for the compound.
   * @param pubchemCid the new PubChem CID for the compound
   */
  public void setPubchemCid(String pubchemCid) {
    _pubchemCid = pubchemCid;
  }

  /**
   * Get the ChemBank ID for the compound.
   * @return the ChemBank ID for the compound
   * 
   * @hibernate.property
   *   type="text"
   *   column="chembank_id"
   */
  public String getChembankId() {
    return _chembankId;
  }
  
  /**
   * Set the ChemBank ID for the compound.
   * @param chembankId the new ChemBank ID for the compound
   */
  public void setChembankId(String chembankId) {
    _chembankId = chembankId;
  }

  
  // identity methods
  
  /**
   * @see java.lang.Object#equals(java.lang.Object)
   */
  @Override
  public boolean equals(Object object) {
    if (! (object instanceof Compound)) {
      return false;
    }
    Compound that = (Compound) object;
    return
      this.getCompoundName().equals(that.getCompoundName());
  }

  /**
   * @see java.lang.Object#hashCode()
   */
  @Override
  public int hashCode() {
    return getCompoundName().hashCode();
  }

  
  // protected getters and setters

  /**
   * Get the modifiable set of wells.
   * @return     the modifiable set of wells
   * @motivation allow efficient maintenance of the bi-directional relationship
   *             between {@link Compound} and {@link Well}.
   */
  protected Set<Well> getModifiableWellSet() {
    return _wells;
  }

  
  // private getters and setters

  /**
   * Set the compound id for the compound.
   * @param compoundId the new compound id for the compound
   * @motivation       for hibernate
   */
  private void setCompoundId(Integer compoundId) {
    _compoundId = compoundId;
  }

  /**
   * Get the version number of the compound.
   * @return     the version number of the compound
   * @motivation for hibernate
   *
   * @hibernate.version
   */
  private Integer getVersion() {
    return _version;
  }

  /**
   * Set the version number of the compound.
   * @param version the new version number for the compound
   * @motivation    for hibernate
   */
  private void setVersion(Integer version) {
    _version = version;
  }

  /**
   * Set the set of wells that contain this compound.
   * @param wells the new set of wells that contain this compound
   * @motivation  for hibernate
   * @motivation  hibernate actually calls this method with the result of
   *              {@link #getWells}, which, for purposes of a coherent public
   *              API for the bean, returns an unmodifiable set. we must in
   *              turn recast the set into a modifiable set, so that further
   *              calls to {@link #addWell} and {@link #removeWell} function
   *              properly.
   */
  private void setWells(Set<Well> wells) {
    _wells = new HashSet<Well>(wells);
  }

  /**
   * Set the set of synonyms for the compound.
   * @param synonyms the new set of synonyms for the compound
   * @motivation     for hibernate
   * @motivation     hibernate actually calls this method with the result of
   *                 {@link #getSynonyms}, which, for purposes of a coherent
   *                 public API for the bean, returns an unmodifiable set. we
   *                 must in turn recast the set into a modifiable set, so that
   *                 further calls to {@link #addSynonym} and
   *                 {@link #removeSynonym} function properly.
   */
  private void setSynonyms(Set<String> synonyms) {
    _synonyms = new HashSet<String>(synonyms);
  }

  /**
   * Set the set of CAS numbers for the compound.
   * @param casNumber the new set of CAS numbers for the compound
   * @motivation      for hibernate
   * @motivation      hibernate actually calls this method with the result of
   *                  {@link #getCasNumbers}, which, for purposes of a coherent
   *                  public API for the bean, returns an unmodifiable set. we
   *                  must in turn recast the set into a modifiable set, so that
   *                  further calls to {@link #addCasNumber} and
   *                  {@link #removeCasNumber} function properly.
   */
  private void setCasNumbers(Set<String> casNumber) {
    _casNumbers = new HashSet<String>(casNumber);
  }

  /**
   * Set the set of NSC numbers for the compound.
   * @param nscNumber the new set of NSC numbers for the compound
   * @motivation      for hibernate
   * @motivation      hibernate actually calls this method with the result of
   *                  {@link #getNscNumbers}, which, for purposes of a coherent
   *                  public API for the bean, returns an unmodifiable set. we
   *                  must in turn recast the set into a modifiable set, so that
   *                  further calls to {@link #addNscNumber} and
   *                  {@link #removeNscNumber} function properly.
   */
  private void setNscNumbers(Set<String> nscNumber) {
    _nscNumbers = new HashSet<String>(nscNumber);
  }
}
