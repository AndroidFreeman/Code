package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProfileRepository extends JpaRepository<Profile, String> {
    List<Profile> findByClassCodeContaining(String classCode);
}
