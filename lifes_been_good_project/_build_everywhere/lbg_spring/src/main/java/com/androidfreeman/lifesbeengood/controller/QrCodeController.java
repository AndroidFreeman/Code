package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.QrCode;
import com.androidfreeman.lifesbeengood.repository.QrCodeRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/qrcodes")
@CrossOrigin(origins = "*", maxAge = 3600)
public class QrCodeController {

    @Autowired private QrCodeRepository qrCodeRepository;
    @Autowired private EventService eventService;

    @GetMapping
    public ApiResponse<List<QrCode>> listQrCodes() {
        return ApiResponse.success(qrCodeRepository.findAll());
    }

    @PostMapping
    @org.springframework.transaction.annotation.Transactional
    public ApiResponse<String> saveQrCodes(@RequestBody Map<String, List<QrCode>> payload) {
        List<QrCode> items = payload.get("items");
        if (items != null) {
            qrCodeRepository.deleteAll();
            qrCodeRepository.saveAll(items);
            eventService.emitModulesChanged("qrcodes");
        }
        return ApiResponse.success("Saved");
    }
}