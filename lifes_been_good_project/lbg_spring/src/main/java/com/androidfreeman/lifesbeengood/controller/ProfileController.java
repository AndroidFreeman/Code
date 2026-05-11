package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.Profile;
import com.androidfreeman.lifesbeengood.repository.ProfileRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/profiles")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ProfileController {

    @Autowired private ProfileRepository profileRepository;
    @Autowired private EventService eventService;

    @GetMapping
    @Cacheable("profiles")
    public ApiResponse<List<Profile>> listProfiles() {
        return ApiResponse.success(profileRepository.findAll());
    }

    @PostMapping
    @CacheEvict(value = "profiles", allEntries = true)
    public ApiResponse<Profile> insertProfile(@RequestBody Profile profile) {
        if (profile.getId() == null || profile.getId().isEmpty()) {
            profile.setId(UUID.randomUUID().toString());
        }
        Profile saved = profileRepository.save(profile);
        eventService.emitModulesChanged("profiles");
        return ApiResponse.success(saved);
    }

    @PutMapping("/{id}/classes")
    @CacheEvict(value = "profiles", allEntries = true)
    public ApiResponse<Profile> updateProfileClasses(@PathVariable String id, @RequestBody Map<String, String> payload) {
        Optional<Profile> opt = profileRepository.findById(id);
        if (opt.isPresent()) {
            Profile profile = opt.get();
            profile.setClassCode(payload.get("class_code"));
            Profile saved = profileRepository.save(profile);
            eventService.emitModulesChanged("profiles", "classes");
            return ApiResponse.success(saved);
        }
        return ApiResponse.error("Profile not found");
    }

    @PostMapping("/{id}/avatar")
    @CacheEvict(value = "profiles", allEntries = true)
    public ApiResponse<Profile> updateAvatar(@PathVariable String id, @RequestBody Map<String, String> payload) {
        Optional<Profile> opt = profileRepository.findById(id);
        if (opt.isPresent()) {
            Profile profile = opt.get();
            profile.setAvatar(payload.get("avatar"));
            Profile saved = profileRepository.save(profile);
            eventService.emitModulesChanged("profiles");
            return ApiResponse.success(saved);
        }
        return ApiResponse.error("Profile not found");
    }
}