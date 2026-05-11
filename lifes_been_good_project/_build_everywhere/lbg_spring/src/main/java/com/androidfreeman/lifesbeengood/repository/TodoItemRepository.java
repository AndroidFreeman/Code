package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.TodoItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TodoItemRepository extends JpaRepository<TodoItem, String> {
}
