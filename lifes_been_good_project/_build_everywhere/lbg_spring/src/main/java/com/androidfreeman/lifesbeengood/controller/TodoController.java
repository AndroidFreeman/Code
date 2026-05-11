package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.TodoItem;
import com.androidfreeman.lifesbeengood.repository.TodoItemRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/todos")
@CrossOrigin(origins = "*", maxAge = 3600)
public class TodoController {

    @Autowired private TodoItemRepository todoItemRepository;
    @Autowired private EventService eventService;

    @GetMapping
    public ApiResponse<List<TodoItem>> listTodos() {
        return ApiResponse.success(todoItemRepository.findAll());
    }

    @PostMapping
    public ApiResponse<TodoItem> addTodo(@RequestBody TodoItem todo) {
        if (todo.getId() == null || todo.getId().isEmpty()) {
            todo.setId(UUID.randomUUID().toString());
        }
        todo.setCreatedAt(java.time.Instant.now().toString());
        todo.setUpdatedAt(java.time.Instant.now().toString());
        TodoItem saved = todoItemRepository.save(todo);
        eventService.emitModulesChanged("todos");
        return ApiResponse.success(saved);
    }

    @PutMapping("/{id}/toggle")
    public ApiResponse<TodoItem> toggleTodo(@PathVariable String id) {
        Optional<TodoItem> opt = todoItemRepository.findById(id);
        if (opt.isPresent()) {
            TodoItem todo = opt.get();
            todo.setDone(!todo.isDone());
            todo.setUpdatedAt(java.time.Instant.now().toString());
            TodoItem saved = todoItemRepository.save(todo);
            eventService.emitModulesChanged("todos");
            return ApiResponse.success(saved);
        }
        return ApiResponse.error("Todo not found");
    }
}