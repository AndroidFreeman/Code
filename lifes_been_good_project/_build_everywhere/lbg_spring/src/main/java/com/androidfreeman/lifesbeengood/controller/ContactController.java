package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.Contact;
import com.androidfreeman.lifesbeengood.repository.ContactRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ContactController {

    @Autowired private ContactRepository contactRepository;

    @GetMapping
    public ApiResponse<List<Contact>> listContacts() {
        return ApiResponse.success(contactRepository.findAll());
    }
}